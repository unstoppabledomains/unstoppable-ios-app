//
//  HomeTabView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct HomeTabView: View {
    
    @StateObject var router: HomeTabRouter
    private let id: UUID

    var body: some View {
        TabView(selection: $router.tabViewSelection) {
            HomeView()
                .modifier(HomeTabViewModifier(tab: .wallets, isTabBarVisible: router.isTabBarVisible))
            
            HomeExploreView(viewModel: HomeExploreViewModel(router: router))
                .modifier(HomeTabViewModifier(tab: .explore, isTabBarVisible: router.isTabBarVisible))
            
            HomeActivityView(viewModel: HomeActivityViewModel(router: router))
                .modifier(HomeTabViewModifier(tab: .activity, isTabBarVisible: router.isTabBarVisible))
            
            ChatListView(viewModel: .init(presentOptions: .default,
                                          router: router))
                .modifier(HomeTabViewModifier(tab: .messaging, isTabBarVisible: router.isTabBarVisible))
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
            ConnectedAppsListView(tabRouter: router)
        })
        .sheet(item: $router.presentedNFT, content: { nft in
            NFTDetailsView(nft: nft)
                .pullUpHandler(router)
        })
        .sheet(item: $router.requestingRecoveryMPC, content: { mpcWalletMetadataDisplayInfo in
            MPCRequestRecoveryView(mpcWalletMetadata: mpcWalletMetadataDisplayInfo.walletMetadata)
                .pullUpHandler(router)
        })
        .sheet(isPresented: $router.showingUpdatedToWalletGreetings, content: {
            UpdateToWalletGreetingsView()
        })
        .sheet(item: $router.showingWalletInfo, content: {
            ShareWalletInfoView(wallet: $0)
                .presentationDetents([.large])
        })
        .sheet(item: $router.mpcResetPasswordData, content: {
            MPCResetPasswordEnterPasswordView(resetPasswordData: $0)
                .interactiveDismissDisabled()
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
                                               sourceScreen: presentationDetails.sourceScreen,
                                               tabRouter: router)
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

// MARK: - Private methods
private extension HomeTabView {
    struct HomeTabViewModifier: ViewModifier {
        @EnvironmentObject var tabRouter: HomeTabRouter

        let tab: HomeTab
        var isTabBarVisible: Bool
        
        func body(content: Content) -> some View {
            content
                .tabItem {
                    Label(title: { Text(tab.title) },
                          icon: { tab == tabRouter.tabViewSelection ? tab.filledIcon : tab.icon })
                }
                .tag(tab)
                .tabBarVisible(isTabBarVisible)
        }
    }
}

#Preview {
    HomeTabView(tabRouter: HomeTabRouter(profile: .wallet(MockEntitiesFabric.Wallet.mockEntities().first!)))
}
