//
//  SearchDomainsView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.10.2023.
//

import SwiftUI
import Combine

struct PurchaseSearchDomainsView: View, ViewAnalyticsLogger {
    
    @Environment(\.purchaseDomainsService) private var purchaseDomainsService
    @StateObject private var debounceObject = DebounceObject()
    @StateObject private var ecommFlagTracker = UDMaintenanceModeFeatureFlagTracker(featureFlag: .isMaintenanceEcommEnabled)
    @State private var suggestions: [DomainToPurchaseSuggestion] = []
    @State private var searchResult: [DomainToPurchase] = []
    @State private var isLoading = false
    @State private var isInspiring = false
    @State private var loadingError: Error?
    @State private var searchingText = ""
    @State private var searchResultType: SearchResultType = .userInput
    @State private var localCart = LocalCart()
    @State private var scrollOffset: CGPoint = .zero
    @State private var skeletonItemsWidth: [CGFloat] = []
    @State private var pullUp: ViewPullUpConfigurationType?

    var domainSelectedCallback: (([DomainToPurchase])->())
    var scrollOffsetCallback: ((CGPoint)->())? = nil
    var analyticsName: Analytics.ViewName { .purchaseDomainsSearch }

    var body: some View {
        currentContentView()
        .animation(.default, value: UUID())
        .background(Color.backgroundDefault)
        .onChange(of: scrollOffset) { newValue in
            scrollOffsetCallback?(newValue)
        }
        .viewPullUp($pullUp)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Views
private extension PurchaseSearchDomainsView {
    @ViewBuilder
    func currentContentView() -> some View {
        if ecommFlagTracker.maintenanceData?.isCurrentlyEnabled == true {
            MaintenanceDetailsFullView(serviceType: .purchaseDomains,
                                           maintenanceData: ecommFlagTracker.maintenanceData)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            contentView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        doneButtonView()
                    }
                }
        }
    }
    
    @ViewBuilder
    func doneButtonView() -> some View {
        Button {
            domainSelectedCallback(localCart.domains)
        } label: {
            Text("Done")
        }
        .disabled(localCart.domains.isEmpty)
    }
    
    @ViewBuilder
    func contentView() -> some View {
        GeometryReader { geom in
            ZStack {
                OffsetObservingScrollView(offset: $scrollOffset) {
                    VStack {
                        headerView()
                        searchView()
                        searchResultView()
                    }
                }
                searchInspirationButton()
                    .offset(y: (geom.size.height / 2) - searchInspirationButtonOffsetToKeyboard)
            }
        }
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.searchForANewDomain.localized())
                .titleText()
                .multilineTextAlignment(.center)
        }
        .padding(EdgeInsets(top: 56, leading: 0, bottom: 0, trailing: 0))
    }
    
    @ViewBuilder
    func searchView() -> some View {
        UDTextFieldView(text: $debounceObject.text,
                        placeholder: "domain.x",
                        hint: nil,
                        rightViewMode: .always,
                        leftViewType: .search,
                        focusBehaviour: .activateOnAppear,
                        keyboardType: .alphabet,
                        autocapitalization: .never,
                        autocorrectionDisabled: true)
        .onChange(of: debounceObject.debouncedText) { text in
            search(text: text, searchType: .userInput)
        }
        .padding(EdgeInsets(top: 16, leading: 16,
                            bottom: 0, trailing: 16))
    }
    
    var currentSearchFieldRightViewType: UDTextFieldView.RightViewType {
        .inspire { isInspiring in
            self.isInspiring = isInspiring
            if isInspiring {
                logButtonPressedAnalyticEvents(button: .inspire)
            } else {
                logButtonPressedAnalyticEvents(button: .cancelInspire)
            }
            searchResult = []
        }
    }
    
    @ViewBuilder
    func searchResultView() -> some View {
        if isLoading && !searchingText.isEmpty {
            loadingView()
        } else if !searchResult.isEmpty {
            resultListView()
        } else if loadingError != nil {
            errorView()
        } else if isInspiring {
            inspiringHintsView()
        } else if !searchingText.isEmpty {
            noResultsView()
        } else if !suggestions.isEmpty {
            trendingListView()
        }
    }
    
    @ViewBuilder
    func loadingView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack {
                ForEach(skeletonItemsWidth, id: \.self) { itemWidth in
                    domainSearchSkeletonRow(itemWidth: itemWidth)
                }
                .setSkeleton(.constant(true),
                             animationType: .solid(.backgroundSubtle))
            }
            .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
        .padding()
    }
    
    @ViewBuilder
    func resultListView() -> some View {
        UDCollectionSectionBackgroundView {
            LazyVStack {
                ForEach(searchResult, id: \.name) { domainInfo in
                    UDCollectionListRowButton(content: {
                        domainSearchResultRow(domainInfo)
                            .udListItemInCollectionButtonPadding()
                    }, callback: {
                        logButtonPressedAnalyticEvents(button: .searchDomains, parameters: [.value: domainInfo.name,
                                                                                            .price: String(domainInfo.price),
                                                                                            .searchType: searchResultType.rawValue])
                        didSelectDomain(domainInfo)
                    })
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        }
        .padding()
    }
    
    @ViewBuilder
    func trendingListView() -> some View {
        UDCollectionSectionBackgroundView(withShadow: true) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image.statsIcon
                        .resizable()
                        .squareFrame(16)
                    Text(String.Constants.trending.localized())
                        .font(.currentFont(size: 14, weight: .semibold))
                }
                .foregroundColor(.foregroundDefault)
                
                FlowLayoutView(suggestions) { suggestion in
                    Button(action: {
                        UDVibration.buttonTap.vibrate()
                        logButtonPressedAnalyticEvents(button: .suggestedName, parameters: [.value: suggestion.name])
                        search(text: suggestion.name, searchType: .suggestion)
                        debounceObject.text = suggestion.name
                    }, label: {
                        Text(suggestion.name)
                            .font(.currentFont(size: 14, weight: .medium))
                            .foregroundColor(.foregroundDefault)
                            .padding(EdgeInsets(top: 8, leading: 12,
                                                bottom: 8, trailing: 12))
                            .background(Color.backgroundMuted2)
                            .cornerRadius(16)
                    })
                }
            }
            .padding()
        }
        .padding()
    }
    
    @ViewBuilder
    func noResultsView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 16) {
                Image.grimaseIcon
                    .resizable()
                    .squareFrame(32)
                    .foregroundColor(.foregroundSecondary)
                VStack(spacing: 8) {
                    Text(String.Constants.noAvailableDomains.localized())
                        .font(.currentFont(size: 20, weight: .bold))
                    Text(String.Constants.tryEnterDifferentName.localized())
                        .font(.currentFont(size: 14))
                }
                .multilineTextAlignment(.center)
                .foregroundColor(.foregroundSecondary)
            }
            .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        }
        .padding()
    }
    
    @ViewBuilder
    func errorView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 16) {
                Image.grimaseIcon
                    .resizable()
                    .squareFrame(32)
                    .foregroundColor(.foregroundSecondary)
                VStack(spacing: 8) {
                    Text(String.Constants.somethingWentWrong.localized())
                        .font(.currentFont(size: 20, weight: .bold))
                    Text(String.Constants.pleaseCheckInternetConnection.localized())
                        .font(.currentFont(size: 14))
                }
                .multilineTextAlignment(.center)
                .foregroundColor(.foregroundSecondary)
            }
            .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        }
        .padding()
    }
    
    @ViewBuilder
    func inspiringHintsView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(AIInspireHints.allCases, id: \.self) { hint in
                    HStack(spacing: 8) {
                        hint.icon
                            .resizable()
                            .squareFrame(16)
                        Text(hint.title)
                            .font(.currentFont(size: 14))
                    }
                    .foregroundStyle(Color.foregroundSecondary)
                    if hint != .hint3 {
                        Line()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3]))
                            .foregroundColor(.black)
                            .opacity(0.06)
                            .frame(height: 1)
                            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                }
            }
            .padding()
        }
        .padding()
    }
  
    @ViewBuilder
    func searchInspirationButton() -> some View {
        if isInspiring,
           KeyboardService.shared.isKeyboardOpened,
           !searchingText.isEmpty {
            ZStack {
                Rectangle()
                    .foregroundStyle(Color.backgroundDefault)
                    .frame(height: searchInspirationButtonStyle.height + searchInspirationButtonOffset * 2)
                UDButtonView(text: String.Constants.search.localized(), style: searchInspirationButtonStyle) {
                    aiSearch(hint: searchingText)
                }
                .padding()
            }
        }
    }
    
    var searchInspirationButtonStyle: UDButtonStyle { .large(.raisedPrimary) }
    var searchInspirationButtonOffset: CGFloat { 16 }
    var searchInspirationButtonOffsetToKeyboard: CGFloat { (searchInspirationButtonStyle.height + searchInspirationButtonOffset) / 2 }
}

// MARK: - Private methods
private extension PurchaseSearchDomainsView {
    func onAppear() {
        setupSkeletonItemsWidth()
        loadSuggestions()
        
    }
    
    func setupSkeletonItemsWidth() {
        guard skeletonItemsWidth.isEmpty else { return }
        
        for _ in 0..<6 {
            let width: CGFloat = 60 + CGFloat(arc4random_uniform(100))
            skeletonItemsWidth.append(width)
        }
    }
    
    func loadSuggestions() {
        guard suggestions.isEmpty else { return }
        
        Task {
            do {
                let suggestions = try await purchaseDomainsService.getDomainsSuggestions(hint: nil)
                self.suggestions = suggestions
            } catch {
                Debugger.printFailure("Failed to load suggestions")
            }
        }
    }
    
    func search(text: String, searchType: SearchResultType) {
        let text = text.trimmedSpaces.lowercased()
        guard searchingText != text else { return }
        searchingText = text
        loadingError = nil
        
        guard !isInspiring else { return }
        searchResult = []
        
        guard !searchingText.isEmpty else { return }
        
        performSearchOperation(searchingText: text, searchType: searchType) {
            try await purchaseDomainsService.searchForDomains(key: text)
        }
    }
    
    func aiSearch(hint: String) {
        searchResult = []
        performSearchOperation(searchingText: hint, searchType: .aiSearch) {
            try await purchaseDomainsService.aiSearchForDomains(hint: hint)
        }
    }
    
    func performSearchOperation(searchingText: String, searchType: SearchResultType, _ block: @escaping () async throws -> ([DomainToPurchase])) {
        Task {
            logAnalytic(event: .didSearch, parameters: [.value: searchingText,
                                                        .searchType: searchType.rawValue])
            
            isLoading = true
            do {
                let searchResult = try await block()
                guard searchingText == self.searchingText else { return } // Result is irrelevant, search query has changed
                
                self.searchResult = sortSearchResult(searchResult, searchText: searchingText)
                self.searchResultType = searchType
            } catch {
                loadingError = error
            }
            isLoading = false
        }
    }
    
    func sortSearchResult(_ searchResult: [DomainToPurchase], searchText: String) -> [DomainToPurchase] {
        var searchResult = searchResult
        /// Move exactly matched domain to the top of the list
        if let i = searchResult.firstIndex(where: { $0.name == searchText }),
           i != 0 {
            let matchingDomain = searchResult[i]
            searchResult.remove(at: i)
            searchResult.insert(matchingDomain, at: 0)
        }
        return searchResult
    }
    
    func didSelectDomain(_ domain: DomainToPurchase) {
        if domain.isAbleToPurchase {
            didSelectDomainToPurchase(domain)
        } else {
            logAnalytic(event: .didSelectNotSupportedDomainForPurchaseInSearch, parameters: [.domainName: domain.name,
                                                                                             .price : String(domain.price),
                                                                                             .searchType: searchResultType.rawValue])
            pullUp = .default(.init(icon: .init(icon: .cartIcon, size: .large),
                           title: .text(String.Constants.purchaseSearchCantButPullUpTitle.localized()),
                           subtitle: .label(.highlightedText(.init(text: String.Constants.purchaseSearchCantButPullUpSubtitle.localized(domain.tld),
                                                                   highlightedText: [.init(highlightedText: domain.tld,
                                                                                           highlightedColor: .foregroundDefault)],
                                                                   analyticsActionName: nil,
                                                                   action: nil))),
                           actionButton: .main(content: .init(title: String.Constants.goToWebsite.localized(),
                                                              analyticsName: .goToWebsite,
                                                              action: {
                openLinkExternally(.unstoppableDomainSearch(searchKey: domain.name))
            })),
                           cancelButton: .gotItButton(),
                           analyticName: .searchPurchaseDomainNotSupported))
        }
    }
    
    func didSelectDomainToPurchase(_ domain: DomainToPurchase) {
        if localCart.isDomainInCart(domain) {
            localCart.removeDomain(domain)
        } else {
            localCart.addDomain(domain)
        }
    }
}

// MARK: - Views
private extension PurchaseSearchDomainsView {
    @ViewBuilder
    func domainSearchResultRow(_ domain: DomainToPurchase) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 16) {
                domainIconView(domain)
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundSuccess)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    .background(Color.backgroundSuccess)
                    .clipShape(Circle())
                Text(domain.name)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
            }
            Spacer()
            Text(formatCartPrice(domain.price))
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
            Image.chevronRight
                .resizable()
                .squareFrame(20)
                .foregroundStyle(Color.foregroundMuted)
        }
        .frame(minHeight: UDListItemView.height)
    }
    
    @ViewBuilder
    func domainIconView(_ domain: DomainToPurchase) -> some View {
        if localCart.isDomainInCart(domain) {
            Image.check
                .resizable()
        } else {
            Image(systemName: "cart.fill.badge.plus")
                .resizable()
        }
    }
    
    @ViewBuilder
    func domainSearchSkeletonRow(itemWidth: CGFloat) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 16) {
                Image.check
                    .squareFrame(40)
                    .skeletonable()
                    .clipShape(Circle())
                Text("")
                    .frame(height: 12)
                    .frame(minWidth: itemWidth)
                    .skeletonable()
                    .skeletonCornerRadius(6)
            }
            Spacer()
            Text("")
                .frame(width: 40,
                       height: 12)
                .skeletonable()
                .skeletonCornerRadius(6)
        }
        .frame(height: UDListItemView.height)
    }
}

// MARK: - Private methods
private extension PurchaseSearchDomainsView {
    enum AIInspireHints: Hashable, CaseIterable {
        case hint1, hint2, hint3
        
        var title: String {
            switch self {
            case .hint1:
                return String.Constants.aiSearchHint1.localized()
            case .hint2:
                return String.Constants.aiSearchHint2.localized()
            case .hint3:
                return String.Constants.aiSearchHint3.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .hint1:
                return .magicWandIcon
            case .hint2:
                return .tapSingleIcon
            case .hint3:
                return .warningIcon
            }
        }
    }
    
    enum SearchResultType: String {
        case userInput
        case suggestion
        case aiSearch
    }
    
    struct LocalCart {
        private(set) var domains: [DomainToPurchase] = []
        
        func isDomainInCart(_ domain: DomainToPurchase) -> Bool {
            domains.firstIndex(where: { $0.name == domain.name }) != nil
        }
        
        mutating func addDomain(_ domain: DomainToPurchase) {
            guard !isDomainInCart(domain) else { return }
            
            domains.append(domain)
        }
        
        mutating func removeDomain(_ domain: DomainToPurchase) {
            if let i = domains.firstIndex(where: { $0.name == domain.name }) {
                domains.remove(at: i)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PurchaseSearchDomainsView(domainSelectedCallback: { _ in })
            .environment(\.purchaseDomainsService, MockFirebaseInteractionsService())
    }
}
