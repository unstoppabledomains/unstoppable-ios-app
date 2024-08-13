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
    private var localCart: PurchaseDomains.LocalCart { viewModel.localCart }
    @State private var suggestions: [DomainToPurchase] = []
    @State private var searchResultHolder: PurchaseDomains.SearchResultHolder = .init()
    @State private var searchFiltersHolder: PurchaseDomains.SearchFiltersHolder = .init()
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
        .sheet(isPresented: $viewModel.localCart.isShowingCart, content: {
            PurchaseDomainsCartView()
        })
        .sheet(isPresented: $searchFiltersHolder.isFiltersVisible, content: {
            PurchaseDomainsSearchFiltersView(appliedFilters: searchFiltersHolder.tlds, 
                                             callback: updateTLDFilters)
        })
        .navigationTitle(String.Constants.buyDomainsSearchTitle.localized())
        .navigationBarTitleDisplayMode(.inline)
        .trackAppearanceAnalytics(analyticsLogger: self)
        .passViewAnalyticsDetails(logger: self)
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
                        filterButtonView()
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        cartButtonView()
                            .padding(.leading, 10)
                    }
                }
                .modifier(PurchaseDomainsCheckoutButton())
        }
    }
    
    @ViewBuilder
    func cartButtonView() -> some View {
        Button {
            logButtonPressedAnalyticEvents(button: .cart)
            UDVibration.buttonTap.vibrate()
            viewModel.localCart.isShowingCart = true
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
    func filterButtonView() -> some View {
        Button {
            logButtonPressedAnalyticEvents(button: .filterOption)
            UDVibration.buttonTap.vibrate()
            searchFiltersHolder.isFiltersVisible = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image.filter
                    .resizable()
                    .squareFrame(28)
                    .foregroundStyle(Color.foregroundDefault)
                if searchFiltersHolder.isFiltersApplied {
                    Circle()
                        .squareFrame(16)
                        .foregroundStyle(Color.foregroundAccent)
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
            emptyStateView()
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
        suggestionsSectionView()
    }
    
    @ViewBuilder
    func resultDomainsListView(_ domains: [DomainToPurchase]) -> some View {
        domainsListViewWith(title: String.Constants.results.localized(),
                            domains: domains)
    }
    
    @ViewBuilder
    func domainsListViewWith(title: String,
                             domains: [DomainToPurchase]) -> some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            sectionTitleView(title)
            ForEach(domains) { domain in
                resultDomainRowView(domain)
            }
        }
    }
    
    @ViewBuilder
    func resultDomainRowView(_ domain: DomainToPurchase) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
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
        if !suggestions.isEmpty {
            domainsListViewWith(title: String.Constants.suggestedForYou.localized(),
                                domains: suggestions)
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
    
    @ViewBuilder
    func emptyStateView() -> some View {
        if searchResultHolder.recentSearches.isEmpty {
            PurchaseSearchEmptyView(mode: .start)
        } else {
            recentSearchesSectionView()
        }
    }
    
    @ViewBuilder
    func recentSearchesSectionView() -> some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            sectionTitleView(String.Constants.recent.localized())
            ForEach(searchResultHolder.recentSearches, id: \.self) { search in
                recentSearchRowView(search)
            }
        }
    }
    
    @ViewBuilder
    func recentSearchRowView(_ search: String) -> some View {
        HStack(spacing: 16) {
            Button {
                logButtonPressedAnalyticEvents(button: .recentSearch, parameters: [.value: search])
                UDVibration.buttonTap.vibrate()
                self.search(text: search, searchType: .recent)
                debounceObject.text = search
            } label: {
                Image.clock
                    .resizable()
                    .squareFrame(24)
                    .foregroundStyle(Color.foregroundSecondary)
                Text(search)
                    .textAttributes(color: .foregroundDefault,
                                    fontSize: 16,
                                    fontWeight: .medium)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button {
                logButtonPressedAnalyticEvents(button: .clearFromRecentSearch, parameters: [.value: search])
                UDVibration.buttonTap.vibrate()
                searchResultHolder.removeRecentSearch(string: search)
            } label: {
                Image.cancelIcon
                    .resizable()
                    .squareFrame(24)
                    .foregroundStyle(Color.foregroundSecondary)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 44)
    }
}

// MARK: - Private methods
private extension PurchaseDomainsSearchView {
    func onAppear() {
        setupSkeletonItemsWidth()
    }
    
    func setupSkeletonItemsWidth() {
        guard skeletonItemsWidth.isEmpty else { return }
        
        for _ in 0..<6 {
            let width: CGFloat = 60 + CGFloat(arc4random_uniform(100))
            skeletonItemsWidth.append(width)
        }
    }
    
    func loadSuggestions() {
        suggestions.removeAll()
        let searchingText = self.searchingText
        Task {
            do {
                let suggestions = try await purchaseDomainsService.getDomainsSuggestions(hint: searchingText,
                                                                                         tlds: searchFiltersHolder.tlds)
                guard searchingText == self.searchingText else { return }
                
                self.suggestions = suggestions
            } catch {
                Debugger.printFailure("Failed to load suggestions")
            }
        }
    }
    
    func updateTLDFilters(_ tlds: Set<String>) {
        self.searchFiltersHolder.setTLDs(tlds)
        
        let searchingText = self.searchingText
        if !searchingText.isEmpty {
            self.searchingText = ""
            self.search(text: searchingText,
                        searchType: self.searchResultType)
        }
    }
    
    func search(text: String, 
                searchType: SearchResultType) {
        let text = text.trimmedSpaces.lowercased()
        guard searchingText != text else { return }
        loadSuggestions()
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
                let filteredResult = searchFiltersHolder.filterDomains(searchResult)
                
                searchResultHolder.setDomains(filteredResult, searchText: searchingText)
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
            logButtonAnalyticsForDomain(domain, button: .domainUnableToPurchase)
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
                moveToPurchaseDomainsFromTheWeb(domain: domain)
            })),
                           cancelButton: .gotItButton(),
                           analyticName: .searchPurchaseDomainNotSupported))
        }
    }
    
    func didSelectDomainToPurchase(_ domain: DomainToPurchase) {
        if domain.isTooExpensiveToBuyInApp {
            logButtonAnalyticsForDomain(domain, button: .expensiveDomain)
            pullUp = .default(.buyDomainFromTheWebsite(goToWebCallback: {
                moveToPurchaseDomainsFromTheWeb(domain: domain)
            }))
        } else if localCart.isDomainInCart(domain) {
            logButtonAnalyticsForDomain(domain, button: .removeDomain)
            viewModel.localCart.removeDomain(domain)
        } else {
            logButtonAnalyticsForDomain(domain, button: .addDomain)
            if !localCart.canAddDomainToCart(domain) {
                pullUp = .default(.checkoutFromTheWebsite(goToWebCallback: {
                    moveToPurchaseDomainsFromTheWeb(domain: domain)
                }))
            } else {
                viewModel.localCart.addDomain(domain)
            }
        }
    }
    
    func logButtonAnalyticsForDomain(_ domain: DomainToPurchase,
                                     button: Analytics.Button) {
        let analyticsParameters: Analytics.EventParameters = [.value: domain.name,
                                                              .price: String(domain.price),
                                                              .searchType: searchResultType.rawValue]
        logButtonPressedAnalyticEvents(button: button, parameters: analyticsParameters)
    }
    
    func moveToPurchaseDomainsFromTheWeb(domain: DomainToPurchase?) {
        openLinkExternally(.unstoppableDomainSearch(searchKey: domain?.name ?? ""))
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
        case recent
        case aiSearch
    }
}

#Preview {
    PurchaseDomains.RecentDomainsToPurchaseSearchStorage.instance.addDomainToPurchaseSearchToRecents("somesearchqueue")
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
