//
//  HomeTabView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

enum HomeTab: String, Hashable {
    case wallets
    case explore
    case messaging
}

struct HomeTabView: View {
    
    @StateObject var router: HomeTabRouter
    private let id: UUID

    var body: some View {
        TabView(selection: $router.tabViewSelection) {
            HomeView()
            .tabItem {
                Label(title: { Text(String.Constants.home.localized()) },
                      icon: { Image.homeLineIcon })
            }
            .tag(HomeTab.wallets)
            .tabBarVisible(router.isTabBarVisible)
            
            HomeExploreView(viewModel: HomeExploreViewModel(router: router))
                .tabItem {
                    Label(title: { Text(String.Constants.explore.localized()) },
                          icon: { Image.exploreIcon })
                }
                .tag(HomeTab.explore)
                .tabBarVisible(router.isTabBarVisible)
            
            ChatListView(viewModel: .init(presentOptions: .default,
                                          router: router))
            .tabItem {
                Label(title: { Text(String.Constants.messages.localized()) },
                      icon: { Image.messageCircleIcon24 })
            }
            .tag(HomeTab.messaging)
            .tabBarVisible(router.isTabBarVisible)
        }
        .tint(.foregroundDefault)
        .onChange(of: router.tabViewSelection, perform: { selectedTab in
            UDVibration.buttonTap.vibrate()
            appContext.analyticsService.log(event: .didSelectHomeTab,
                                            withParameters: [.tab : selectedTab.rawValue])
        })
        .viewPullUp(router.currentPullUp(id: id))
        .modifier(ShowingWalletSelectionModifier(isSelectWalletPresented: $router.isSelectProfilePresented))
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
        .sheet(isPresented: $router.showingUpdatedToWalletGreetings, content: {
            UpdateToWalletGreetingsView()
        })
        .sheet(item: $router.showingWalletInfo, content: {
            ShareWalletInfoView(wallet: $0)
                .presentationDetents([.large])
        })
        .sheet(item: $router.sendCryptoInitialData, content: { initialData in
            SendCryptoAssetRootView(viewModel: SendCryptoAssetViewModel(initialData: initialData))
        })
        .sheet(item: $router.resolvingPrimaryDomainWallet, content: { presentationDetails in
            ReverseResolutionSelectionView(wallet: presentationDetails.wallet,
                                           mode: presentationDetails.mode,
                                           domainSetCallback: presentationDetails.domainSetCallback)
            .interactiveDismissDisabled(presentationDetails.mode == .selectFirst)
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
        .sheet(item: $router.presentedPublicDomain, content: { configuration in
            PublicProfileView(configuration: configuration)
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

#Preview {
    HomeTabView(tabRouter: HomeTabRouter(profile: .wallet(MockEntitiesFabric.Wallet.mockEntities().first!)))
}
