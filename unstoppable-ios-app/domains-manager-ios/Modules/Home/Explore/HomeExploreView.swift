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
    
    var isOtherScreenPushed: Bool { !tabRouter.exploreTabNavPath.isEmpty }
    var analyticsName: Analytics.ViewName { .homeExplore }

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            VStack(spacing: 0) {
                if viewModel.isSearchActive {
                    domainSearchTypeSelector()
                }
                contentList()
            }
            .animation(.default, value: UUID())
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(viewModel)
            .trackAppearanceAnalytics(analyticsLogger: self)
            .passViewAnalyticsDetails(logger: self)
            .displayError($viewModel.error)
            .background(Color.backgroundMuted2)
            .onReceive(keyboardPublisher) { value in
                viewModel.isKeyboardActive = value
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
            .onChange(of: tabRouter.exploreTabNavPath) { path in
                withAnimation {
                    tabRouter.isTabBarVisible = !isOtherScreenPushed
                    if path.isEmpty {
                        setupTitle()
                    } else {
                        setTitleVisibility()
                    }
                }
            }
            .navigationDestination(for: HomeExploreNavigationDestination.self) { destination in
                HomeExploreLinkNavigationDestination.viewFor(navigationDestination: destination,
                                                             tabRouter: tabRouter)
                .environmentObject(navigationState!)
                .environmentObject(viewModel)
            }
            .toolbar(content: {
                // To keep nav bar background visible when scrolling
                ToolbarItem(placement: .topBarLeading) {
                    Color.clear
                }
            })
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
        navigationState?.setCustomTitle(customTitle: { HomeProfileSelectorNavTitleView() },
                                        id: UUID().uuidString)
        setTitleVisibility()
    }
    
    func setTitleVisibility() {
        withAnimation {
            navigationState?.isTitleVisible = !viewModel.isSearchActive && viewModel.searchKey.isEmpty &&
            !isOtherScreenPushed
        }
    }
    
    func setSearchFieldActive(_ active: Bool) {
        /*
         @available(iOS 17, *)
         Bind isPresented to viewModel.keyboardFocused
         .searchable(text: $viewModel.searchText,
         isPresented: $viewModel.isKeyboardActive,
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
        }.environment(\.defaultMinListRowHeight, 28)
        .listStyle(.plain)
        .listRowSpacing(0)
        .sectionSpacing(0)
        .searchable(if: viewModel.isProfileAvailable,
                    text: $viewModel.searchKey,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: String.Constants.searchProfiles.localized())
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
        if viewModel.isProfileAvailable {
            HomeExploreSuggestedProfilesSectionView()
            HomeExploreSeparatorView()
            HomeExploreFollowersSectionView()
                .listRowInsets(.init(horizontal: 16))
        } else {
            HomeExploreEmptyStateView(state: .noProfile)
                .padding(EdgeInsets(top: 32, leading: 0, bottom: 12, trailing: 0))
            HomeExploreSeparatorView()
            HomeExploreTrendingProfilesSectionView()
        }
    }
}

// MARK: - Search Active views
private extension HomeExploreView {
    @ViewBuilder
    func listContentForSearchActive() -> some View {
        switch viewModel.searchDomainsType {
        case .global:
            if viewModel.searchKey.isEmpty {
                HomeExploreRecentProfilesSectionView()
            }
            HomeExploreGlobalSearchResultSectionView()
        case .local:
            HomeExploreUserWalletDomainsView()
        }
    }
}

extension View {
    @ViewBuilder
    func searchable(if condition: Bool,
                    text: Binding<String>,
                    placement: SearchFieldPlacement = .automatic,
                    prompt: String) -> some View {
        if condition {
            self.searchable(text: text,
                            placement: placement,
                            prompt: prompt)
        } else {
            self
        }
    }
}

#Preview {
    let router = MockEntitiesFabric.Home.createHomeTabRouter()
    let viewModel = MockEntitiesFabric.Explore.createViewModelUsing(router)
    
    return HomeExploreView(viewModel: viewModel)
        .environmentObject(router)
}
