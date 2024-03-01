//
//  HomeExploreView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.02.2024.
//

import SwiftUI

struct HomeExploreView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @State private var navigationState: NavigationStateManager?
    @StateObject var viewModel: HomeExploreViewModel
    
    var isOtherScreenPushed: Bool { !tabRouter.chatTabNavPath.isEmpty }
    var analyticsName: Analytics.ViewName { .homeExplore }

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            VStack(spacing: 0) {
                if viewModel.isSearchActive {
                    domainSearchTypeSelector()
                }
                contentList()
            }
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(viewModel)
            .passViewAnalyticsDetails(logger: self)
            .displayError($viewModel.error)
            .background(Color.backgroundMuted2)
            .onReceive(keyboardPublisher) { value in
                viewModel.isSearchActive = value
                if !value {
                    UDVibration.buttonTap.vibrate()
                }
            }
            .onChange(of: viewModel.isSearchActive) { keyboardFocused in
                setSearchFieldActive(keyboardFocused)
                setTitleVisibility()
            }
            .onChange(of: viewModel.searchKey) { keyboardFocused in
                setTitleVisibility()
            }
            .onChange(of: tabRouter.chatTabNavPath) { path in
                tabRouter.isTabBarVisible = !isOtherScreenPushed
                if path.isEmpty {
                    withAnimation {
                        setupTitle()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeExploreNavigationDestination.self) { destination in
                HomeExploreLinkNavigationDestination.viewFor(navigationDestination: destination,
                                                          tabRouter: tabRouter)
                .environmentObject(navigationState!)
            }
        }, navigationStateProvider: { state in
            self.navigationState = state
        }, path: $tabRouter.exploreTabNavPath)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension HomeExploreView {
    func onAppear() {
        setupTitle()
    }
    
    func setupTitle() {
        navigationState?.setCustomTitle(customTitle: { HomeProfileSelectorNavTitleView(profile: viewModel.selectedProfile) },
                                        id: UUID().uuidString)
        navigationState?.isTitleVisible = true
    }
    
    func setTitleVisibility() {
        withAnimation {
            navigationState?.isTitleVisible = !viewModel.isSearchActive && viewModel.searchKey.isEmpty
        }
    }
    
    func setSearchFieldActive(_ active: Bool) {
        /*
         @available(iOS 17, *)
         Bind isPresented to viewModel.keyboardFocused
         .searchable(text: $viewModel.searchText,
         isPresented: $viewModel.isSearchActive,
         placement: .navigationBarDrawer(displayMode: .automatic),
         prompt: Text(String.Constants.search.localized()))
         */
        
        guard let searchBar = findFirstUIViewOfType(UISearchBar.self) else { return }
        
        if active {
            searchBar.becomeFirstResponder()
        } else {
            searchBar.resignFirstResponder()
        }
    }
}

// MARK: - Domains views
private extension HomeExploreView {
    @ViewBuilder
    func domainSearchTypeSelector() -> some View {
        HomeExploreDomainSearchTypePickerView()
            .background(.regularMaterial)
    }
    
    @ViewBuilder
    func contentList() -> some View {
        List {
            currentListContent()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .unstoppableListRowInset()
        }
        .listStyle(.plain)
        .listRowSpacing(0)
        .searchable(text: $viewModel.searchKey,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text(String.Constants.search.localized()))
        .clearListBackground()
    }
    @ViewBuilder
    func currentListContent() -> some View {
        if viewModel.isSearchActive {
            listContentForSearchActive()
        } else {
            listContentForSearchInactive()
        }
    }
}
   
// MARK: - Search Inactive views
private extension HomeExploreView {
    @ViewBuilder
    func listContentForSearchInactive() -> some View {
        HomeExploreTrendingProfilesSectionView()
        followersSection()
    }
    
    @ViewBuilder
    func followersSection() -> some View {
        HomeExploreFollowersSectionView()
            .listRowInsets(.init(horizontal: 16))
    }
    
    @ViewBuilder
    func sectionSeparatorView() -> some View {
        Line(direction: .horizontal)
            .stroke(style: StrokeStyle(lineWidth: 1))
            .foregroundStyle(Color.white.opacity(0.08))
            .shadow(color: .black, radius: 0, x: 0, y: -1)
            .frame(height: 1)
            .listRowInsets(.init(horizontal: 16))
    }
}

// MARK: - Search Active views
private extension HomeExploreView {
    @ViewBuilder
    func listContentForSearchActive() -> some View {
        switch viewModel.searchDomainsType {
        case .global:
            HomeExploreRecentProfilesSectionView()
            domainsList()
        case .local:
            HomeExploreUserWalletDomainsView()
        }
    }
    
    @ViewBuilder
    func domainsList() -> some View {
        domainsView()
            .listRowInsets(.init(horizontal: 16))
    }
    
    @ViewBuilder
    func domainsView() -> some View {
        if viewModel.domainsToShow.isEmpty && viewModel.globalProfiles.isEmpty && !viewModel.isLoadingGlobalProfiles {
            if viewModel.userDomains.isEmpty {
                emptyStateFor(type: .noDomains)
            } else {
                emptyStateFor(type: .noResult)
            }
        } else {
            if !viewModel.domainsToShow.isEmpty {
                domainsSection(viewModel.domainsToShow)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
                
            }
            if !viewModel.globalProfiles.isEmpty {
                discoveredProfilesSection(viewModel.globalProfiles)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
            }
        }
    }
    
    @ViewBuilder
    func domainsSection(_ domains: [DomainDisplayInfo]) -> some View {
        sectionHeaderViewWith(title: String.Constants.yourDomains.localized())
        Section {
            ForEach(domains) { domain in
                domainsRowView(domain)
            }
        }
    }
    
    @ViewBuilder
    func domainsRowView(_ domain: DomainDisplayInfo) -> some View {
        UDCollectionListRowButton(content: {
            DomainSearchResultDomainRowView(domain: domain)
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logAnalytic(event: .domainPressed, parameters: [.domainName : domain.name])
            viewModel.didTapUserDomainProfile(domain)
        })
    }
    
    @ViewBuilder
    func discoveredProfilesSection(_ profiles: [SearchDomainProfile]) -> some View {
        sectionHeaderViewWith(title: String.Constants.globalSearch.localized())
        Section {
            ForEach(profiles, id: \.name) { profile in
                discoveredProfileRowView(profile)
            }
        }
    }
    
    @ViewBuilder
    func discoveredProfileRowView(_ profile: SearchDomainProfile) -> some View {
        UDCollectionListRowButton(content: {
            DomainSearchResultProfileRowView(profile: profile)
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logAnalytic(event: .searchProfilePressed, parameters: [.domainName : profile.name])
            viewModel.didTapSearchDomainProfile(profile)
        })
    }
    
    @ViewBuilder
    func sectionHeaderViewWith(title: String) -> some View {
        Text(title)
            .font(.currentFont(size: 14, weight: .medium))
            .foregroundStyle(Color.foregroundSecondary)
    }
    
    @ViewBuilder
    func emptyStateFor(type: EmptyStateType) -> some View {
        ZStack {
            VStack(spacing: 16) {
                Text(type.title)
                    .font(.currentFont(size: 22, weight: .bold))
                    .frame(height: 28)
                
                if let subtitle = type.subtitle {
                    Text(subtitle)
                        .font(.currentFont(size: 16))
                        .frame(height: 24)
                }
            }
            .foregroundStyle(Color.foregroundSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    enum EmptyStateType {
        case noDomains, noResult
        
        var title: String {
            switch self {
            case .noDomains:
                return "No domains in your wallet"
            case .noResult:
                return String.Constants.noResults.localized()
            }
        }
        
        
        var subtitle: String? {
            switch self {
            case .noDomains:
                return "Use the search to explore people's profiles."
            case .noResult:
                return nil
            }
        }
    }
}

#Preview {
    let router = MockEntitiesFabric.Home.createHomeTabRouter()
    
    return HomeExploreView(viewModel: .init(router: router))
        .environmentObject(router)
}
