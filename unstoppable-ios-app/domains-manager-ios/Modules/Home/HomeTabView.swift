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
    private let id: UUID

    var body: some View {
        TabView(selection: $router.tabViewSelection) {
            currentWalletView()
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
        .onChange(of: router.tabViewSelection, perform: { _ in
            UDVibration.buttonTap.vibrate()
        })
        .viewPullUp(router.currentPullUp(id: id))
        .modifier(ShowingWalletSelection(isSelectWalletPresented: $router.isSelectProfilePresented))
        .sheet(isPresented: $router.isConnectedAppsListPresented, content: {
            ConnectedAppsListViewControllerWrapper(scanCallback: {
                router.showQRScanner()
            })
                .ignoresSafeArea()
                .pullUpHandler(router)
        })
        .sheet(item: $router.presentedNFT, content: { nft in
            NFTDetailsView(nft: nft)
                .pullUpHandler(router)
        })
        .sheet(item: $router.showingWalletInfo, content: {
            ShareWalletInfoView(wallet: $0)
                .presentationDetents([.large])
        })
        .sheet(item: $router.resolvingPrimaryDomainWallet, content: { wallet in
            ReverseResolutionSelectionView(wallet: wallet)
                .interactiveDismissDisabled(true)
        })
        .sheet(item: $router.presentedDomain, content: { presentationDetails in
            DomainProfileViewControllerWrapper(domain: presentationDetails.domain,
                                               wallet: presentationDetails.wallet,
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
    
    init(tabRouter: HomeTabRouter) {
        self._router = StateObject(wrappedValue: tabRouter)
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
                    UserProfileSelectionView()
                        .adaptiveSheet()
                })
        }
    }
    
    @ViewBuilder
    func currentWalletView() -> some View {
        switch router.profile {
        case .wallet(let wallet):
            HomeWalletView(viewModel: .init(selectedWallet: wallet,
                                            router: router))
        case .webAccount(let user):
            HomeWebView(user: user)
        }
    }
}

#Preview {
    HomeTabView(tabRouter: HomeTabRouter(profile: .wallet(MockEntitiesFabric.Wallet.mockEntities().first!)))
}
