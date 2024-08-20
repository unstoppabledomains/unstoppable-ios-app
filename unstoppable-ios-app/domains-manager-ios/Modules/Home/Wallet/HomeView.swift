//
//  HomeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.02.2024.
//

import SwiftUI

struct HomeView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @StateObject private var stateManagerWrapper = NavigationStateManagerWrapper()
    
    var analyticsName: Analytics.ViewName { .home }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.profileId: tabRouter.profile.id] }

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            currentWalletView()
                .navigationDestination(for: HomeWalletNavigationDestination.self) { destination in
                    HomeWalletLinkNavigationDestination.viewFor(navigationDestination: destination)
                        .environmentObject(stateManagerWrapper)
                }
                .trackAppearanceAnalytics(analyticsLogger: self)
                .passViewAnalyticsDetails(logger: self)
                .checkPendingEventsOnAppear()
                .environmentObject(stateManagerWrapper)
        }, navigationStateProvider: { state in
            self.stateManagerWrapper.navigationState = state
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
                                            router: tabRouter))
        case .webAccount(let user):
            HomeWebAccountView(user: user)
        }
    }
}

#Preview {
    let router = HomeTabRouter(profile: .wallet(MockEntitiesFabric.Wallet.mockEntities().first!))
    return HomeView()
        .environmentObject(router)
}
