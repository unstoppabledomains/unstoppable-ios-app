//
//  SearchDomainsView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.10.2023.
//

import SwiftUI
import Combine

struct PurchaseDomainsSearchView: View, ViewAnalyticsLogger {
    
    @Environment(\.purchaseDomainsService) private var purchaseDomainsService
    @EnvironmentObject var viewModel: PurchaseDomainsViewModel
    @StateObject private var debounceObject = DebounceObject()
    @StateObject private var ecommFlagTracker = UDMaintenanceModeFeatureFlagTracker(featureFlag: .isMaintenanceEcommEnabled)
    @StateObject private var localCart = PurchaseDomains.LocalCart()
    @State private var suggestions: [DomainToPurchaseSuggestion] = []
    @State private var searchResultHolder: PurchaseDomains.SearchResultHolder = .init()
    @State private var isLoading: Bool = false
    @State private var loadingError: Error?
    @State private var searchingText: String = ""
    @State private var searchResultType: SearchResultType = .userInput
    @State private var skeletonItemsWidth: [CGFloat] = []
    @State private var pullUp: ViewPullUpConfigurationType?    

    var analyticsName: Analytics.ViewName { .purchaseDomainsSearch }

    var body: some View {
        currentContentView()
        .animation(.default, value: UUID())
        .background(Color.backgroundDefault)
        .viewPullUp($pullUp)
        .onAppear(perform: onAppear)
        .sheet(isPresented: $localCart.isShowingCart, content: {
            PurchaseDomainsCartView()
        })
        .environmentObject(localCart)
        .navigationTitle(String.Constants.buyDomainsSearchTitle.localized())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Views
private extension PurchaseDomainsSearchView {
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
                        cartButtonView()
                    }
                }
                .modifier(PurchaseDomainsCheckoutButton())
        }
    }
    
    @ViewBuilder
    func cartButtonView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            localCart.isShowingCart = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image.cartIcon
                    .resizable()
                    .squareFrame(28)
                    .foregroundStyle(Color.foregroundDefault)
                if !localCart.domains.isEmpty {
                    Text("\(localCart.domains.count)")
                        .textAttributes(color: .foregroundDefault,
                                        fontSize: 11,
                                        fontWeight: .semibold)
                        .padding(.horizontal, 4)
                        .frame(height: 16)
                        .frame(minWidth: 16)
                        .background(Color.foregroundAccent)
                        .clipShape(.capsule)
                        .offset(x: 6, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.default, value: localCart.domains)
    }
    
    @ViewBuilder
    func contentView() -> some View {
        ScrollView {
            VStack(spacing: 10) {
                searchView()
                searchResultView()
                    .padding(.top, 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    @ViewBuilder
    func searchView() -> some View {
        UDTextFieldView(text: $debounceObject.text,
                        placeholder: String.Constants.searchForADomain.localized(),
                        hint: nil,
                        rightViewMode: .always,
                        leftViewType: .search,
                        focusBehaviour: .activateOnAppear,
                        keyboardType: .alphabet,
                        autocapitalization: .never,
                        autocorrectionDisabled: true,
                        height: 36)
        .onChange(of: debounceObject.debouncedText) { text in
            search(text: text, searchType: .userInput)
        }
    }
    
    @ViewBuilder
    func searchResultView() -> some View {
        if isLoading && !searchingText.isEmpty {
            loadingView()
        } else if !searchResultHolder.isEmpty {
            resultListView()
        } else if loadingError != nil {
            errorView()
        } else if !searchingText.isEmpty {
            noResultsView()
        } else {
            PurchaseSearchEmptyView(mode: .start)
        }
    }
    
    @ViewBuilder
    func loadingView() -> some View {
        VStack {
            ForEach(skeletonItemsWidth, id: \.self) { itemWidth in
                domainSearchSkeletonRow(itemWidth: itemWidth)
            }
            .setSkeleton(.constant(true),
                         animationType: .solid(.backgroundSubtle))
        }
    }
    
    @ViewBuilder
    func sectionTitleView(_ title: String) -> some View {
        Text(title)
            .textAttributes(color: .foregroundDefault,
                            fontSize: 16,
                            fontWeight: .medium)
            .frame(height: 24)
    }
    
    @ViewBuilder
    func resultListView() -> some View {
        if searchResultHolder.isShowingTakenDomains {
            resultDomainsListView(searchResultHolder.allDomains)
        } else {
            resultDomainsListView(searchResultHolder.availableDomains)
        }
        if searchResultHolder.hasTakenDomains {
            showHideTakenDomainsView()
        }
    }
    
    @ViewBuilder
    func resultDomainsListView(_ domains: [DomainToPurchase]) -> some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            sectionTitleView(String.Constants.results.localized())
            ForEach(domains) { domain in
                resultDomainRowView(domain)
            }
        }
    }
    
    @ViewBuilder
    func resultDomainRowView(_ domain: DomainToPurchase) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: .searchDomains,
                                           parameters: [.value: domain.name,
                                                        .price: String(domain.price),
                                                        .searchType: searchResultType.rawValue])
            didSelectDomain(domain)
        } label: {
            PurchaseDomainsSearchResultRowView(domain: domain,
                                               mode: .list)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(domain.isTaken)
    }
    
    @ViewBuilder
    func showHideTakenDomainsView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            withAnimation {
                searchResultHolder.isShowingTakenDomains.toggle()
            }
        } label: {
            HStack(spacing: 18) {
                currentShowHideImage
                    .resizable()
                    .squareFrame(20)
                
                Text(currentShowHideTitle)
                    .textAttributes(color: .foregroundSecondary,
                                    fontSize: 14,
                                    fontWeight: .medium)
                    .underline()
                Spacer()
            }
            .foregroundStyle(Color.foregroundSecondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    var currentShowHideImage: Image {
        searchResultHolder.isShowingTakenDomains ? .chevronUp : .chevronDown
    }
    
    var currentShowHideTitle: String {
        searchResultHolder.isShowingTakenDomains ? String.Constants.buyDomainsSearchResultShowLessTitle.localized() : String.Constants.buyDomainsSearchResultShowMoreTitle.localized()
    }
    
    @ViewBuilder
    func suggestionsSectionView() -> some View {
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
    }
    
    @ViewBuilder
    func noResultsView() -> some View {
        PurchaseSearchEmptyView(mode: .noResults)
    }
    
    @ViewBuilder
    func errorView() -> some View {
        PurchaseSearchEmptyView(mode: .error)
    }
}

// MARK: - Private methods
private extension PurchaseDomainsSearchView {
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
        
        searchResultHolder.clear()
        
        guard !searchingText.isEmpty else { return }
        
        performSearchOperation(searchingText: text, searchType: searchType) {
            try await purchaseDomainsService.searchForDomains(key: text)
        }
    }
    
    func aiSearch(hint: String) {
        searchResultHolder.clear()
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
                
                searchResultHolder.setDomains(searchResult, searchText: searchingText)
                self.searchResultType = searchType
            } catch {
                loadingError = error
            }
            isLoading = false
        }
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
private extension PurchaseDomainsSearchView {
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
private extension PurchaseDomainsSearchView {
    enum SearchResultType: String {
        case userInput
        case suggestion
        case aiSearch
    }
}

#Preview {
    let router = MockEntitiesFabric.Home.createHomeTabRouter()
    let viewModel = PurchaseDomainsViewModel(router: router)
    let stateWrapper = NavigationStateManagerWrapper()
    
    return NavigationStack {
        PurchaseDomainsSearchView()
            .environment(\.purchaseDomainsService, MockFirebaseInteractionsService())
            .environmentObject(stateWrapper)
            .environmentObject(router)
            .environmentObject(viewModel)
    }
}
