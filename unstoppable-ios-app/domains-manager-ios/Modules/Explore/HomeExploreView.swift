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
            ZStack {
              
//                if viewModel.isLoading {
                    ProgressView()
//                }
            }
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
                withAnimation {
                    navigationState?.isTitleVisible = !keyboardFocused
                }
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
            .navigationDestination(for: HomeChatNavigationDestination.self) { destination in
                HomeChatLinkNavigationDestination.viewFor(navigationDestination: destination,
                                                          tabRouter: tabRouter)
                .environmentObject(navigationState!)
            }
        }, navigationStateProvider: { state in
            self.navigationState = state
        }, path: $tabRouter.chatTabNavPath)
        .onAppear(perform: onAppear)
        .searchable(text: $viewModel.searchKey,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text(String.Constants.search.localized()))
    }
}

// MARK: - Open methods
extension HomeExploreView {
    func onAppear() {
        setupTitle()
    }
    
    func setupTitle() {
        navigationState?.setCustomTitle(customTitle: { HomeProfileSelectorNavTitleView(profile: viewModel.selectedProfile) },
                                        id: UUID().uuidString)
        navigationState?.isTitleVisible = true
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

#Preview {
    let router = MockEntitiesFabric.Home.createHomeTabRouter()
    
    return HomeExploreView(viewModel: .init(router: router))
        .environmentObject(router)
}
