//
//  HomeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.02.2024.
//

import SwiftUI

struct HomeView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @State private var navigationState: NavigationStateManager?
    @State private var isNavTitleVisible: Bool = true
    @State private var isTabBarVisible: Bool = true
    var analyticsName: Analytics.ViewName { .home }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.profileId: tabRouter.profile.id] }

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            currentWalletView()
                .onChange(of: isNavTitleVisible) { _ in
                    withAnimation {
                        navigationState?.isTitleVisible = isNavTitleVisible
                    }
                }
                .onChange(of: isTabBarVisible) { _ in
                    tabRouter.isTabBarVisible = isTabBarVisible
                }
                .navigationDestination(for: HomeWalletNavigationDestination.self) { destination in
                    HomeWalletLinkNavigationDestination.viewFor(navigationDestination: destination)
                        .ignoresSafeArea()
                }
                .trackAppearanceAnalytics(analyticsLogger: self)
                .environment(\.analyticsViewName, analyticsName)
                .environment(\.analyticsAdditionalProperties, additionalAppearAnalyticParameters)
                .checkPendingEventsOnAppear()

        }, navigationStateProvider: { state in
            self.navigationState = state
        }, path: $tabRouter.walletViewNavPath)
    }
    
}

// MARK: - Private methods
private extension HomeView {
    @ViewBuilder
    func currentWalletView() -> some View {
        switch tabRouter.profile {
        case .wallet(let wallet):
            HomeWalletView(viewModel: .init(selectedWallet: wallet,
                                            router: tabRouter),
                           navigationState: navigationState,
                           isNavTitleVisible: $isNavTitleVisible,
                           isTabBarVisible: $isTabBarVisible)
        case .webAccount(let user):
            HomeWebAccountView(user: user,
                               navigationState: navigationState,
                               isNavTitleVisible: $isNavTitleVisible,
                               isTabBarVisible: $isTabBarVisible)
        }
    }
}

#Preview {
    let router = HomeTabRouter(profile: .wallet(MockEntitiesFabric.Wallet.mockEntities().first!))
    return HomeView()
        .environmentObject(router)
}
