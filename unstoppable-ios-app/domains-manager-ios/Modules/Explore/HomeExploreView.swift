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
            List {
                followersSection(relationshipType: .following)
                sectionSeparatorView()
                followersSection(relationshipType: .followers)

            }
            .listStyle(.plain)
            .listRowSpacing(0)
            .clearListBackground()
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchKey,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: Text(String.Constants.search.localized()))
            .environmentObject(viewModel)
            .environment(\.analyticsViewName, analyticsName)
            .environment(\.analyticsAdditionalProperties, additionalAppearAnalyticParameters)
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

// MARK: - Private methods
private extension HomeExploreView {
    @ViewBuilder
    func followersSection(relationshipType: DomainProfileFollowerRelationshipType) -> some View {
        HomeExploreFollowersSectionView(relationshipType: relationshipType)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.init(horizontal: 16))
    }
    
    @ViewBuilder
    func sectionSeparatorView() -> some View {
        Line(direction: .horizontal)
            .stroke(style: StrokeStyle(lineWidth: 1))
            .foregroundStyle(Color.white.opacity(0.08))
            .shadow(color: .black, radius: 0, x: 0, y: -1)
            .frame(height: 1)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.init(horizontal: 16))
    }
}

#Preview {
    let router = MockEntitiesFabric.Home.createHomeTabRouter()
    
    return HomeExploreView(viewModel: .init(router: router))
        .environmentObject(router)
}
