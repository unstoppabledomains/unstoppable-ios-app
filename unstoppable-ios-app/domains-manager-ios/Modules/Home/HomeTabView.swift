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
            HomeWalletView(viewModel: .init(selectedWallet: selectedWallet,
                                            router: router))
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
        .viewPullUp(router.currentPullUp(id: id))
        .modifier(ShowingWalletSelection(isSelectWalletPresented: $router.isSelectWalletPresented))
        .sheet(item: $router.presentedNFT, content: { nft in
            NFTDetailsView(nft: nft)
                .pullUpHandler(router)
        })
        .sheet(item: $router.resolvingPrimaryDomainWallet, content: { wallet in
            ReverseResolutionSelectionView(wallet: wallet)
                .interactiveDismissDisabled(true)
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
                              preRequestedAction: presentationDetails.preRequestedAction,
                              delegate: presentationDetails.delegate)
                .pullUpHandler(router)
        })
        .fullScreenCover(item: $router.presentedUBTSearch, content: { presentationDetails in
            UDBTSearchView(controller: UBTController(),
                           searchResultCallback: presentationDetails.searchResultCallback)
        })
        .environmentObject(router)
    }
    
    init(selectedWallet: WalletEntity,
         tabRouter: HomeTabRouter) {
        self._router = StateObject(wrappedValue: tabRouter)
        self.selectedWallet = selectedWallet
        self.id = tabRouter.id
        UITabBar.appearance().unselectedItemTintColor = .foregroundSecondary
    }
}

// MARK: - Private methods
private extension HomeTabView {
    struct ShowingWalletSelection: ViewModifier {
        @Binding var isSelectWalletPresented: Bool
        
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $isSelectWalletPresented, content: {
                    HomeWalletWalletSelectionView()
                        .adaptiveSheet()
                })
        }
    }
}

#Preview {
    HomeTabView(selectedWallet: MockEntitiesFabric.Wallet.mockEntities().first!, tabRouter: HomeTabRouter())
}
