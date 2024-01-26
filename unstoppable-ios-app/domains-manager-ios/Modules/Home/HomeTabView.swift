//
//  HomeTabView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

enum HomeTab: Hashable {
    case wallets
    case messaging
}

struct HomeTabView: View {
    
    @StateObject var router: HomeTabRouter
    let selectedWallet: WalletEntity
    private let id: UUID

    var body: some View {
        TabView(selection: $router.tabViewSelection) {
            HomeWalletView(viewModel: .init(selectedWallet: selectedWallet))
            .tabItem {
                Label(title: { Text(String.Constants.home.localized()) },
                      icon: { Image.homeLineIcon })
            }
            .tag(HomeTab.wallets)
            .tabBarVisible(router.isTabBarVisible)
            
            ChatsListViewControllerWrapper(tabState: router)
                .ignoresSafeArea()
            .tabItem {
                Label(title: { Text(String.Constants.messages.localized()) },
                      icon: { Image.messageCircleIcon24 })
            }
            .tag(HomeTab.messaging)
            .tabBarVisible(router.isTabBarVisible)
        }
        .tint(.foregroundDefault)
        .environmentObject(router)
        .viewPullUp(router.currentPullUp(id: id))
        .sheet(item: $router.presentedNFT, content: { nft in
            NFTDetailsView(nft: nft)
                .pullUpHandler(router)
        })
        .sheet(item: $router.presentedDomain, content: { presentationDetails in
            DomainProfileViewControllerWrapper(domain: presentationDetails.domain,
                                               wallet: presentationDetails.wallet.udWallet,
                                               walletInfo: presentationDetails.wallet.displayInfo,
                                               preRequestedAction: presentationDetails.preRequestedProfileAction,
                                               sourceScreen: .domainsCollection,
                                               dismissCallback: presentationDetails.dismissCallback)
            .ignoresSafeArea()
            .pullUpHandler(router)
        })
        .sheet(item: $router.presentedPublicDomain, content: { presentationDetails in
            PublicProfileView(domain: presentationDetails.domain,
                              viewingDomain: presentationDetails.viewingDomain,
                              preRequestedAction: presentationDetails.preRequestedAction)
                .pullUpHandler(router)
        })
        .fullScreenCover(item: $router.presentedUBTSearch, content: { presentationDetails in
            UDBTSearchView(controller: UBTController(),
                           searchResultCallback: presentationDetails.searchResultCallback)
        })
    }
    
    init(selectedWallet: WalletEntity,
         tabRouter: HomeTabRouter) {
        self._router = StateObject(wrappedValue: tabRouter)
        self.selectedWallet = selectedWallet
        self.id = tabRouter.id
        UITabBar.appearance().unselectedItemTintColor = .foregroundSecondary
    }
}

#Preview {
    HomeTabView(selectedWallet: MockEntitiesFabric.Wallet.mockEntities().first!, tabRouter: HomeTabRouter())
}
