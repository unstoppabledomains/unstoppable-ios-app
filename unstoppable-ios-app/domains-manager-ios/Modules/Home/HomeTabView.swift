//
//  HomeTabView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

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
            .tag(0)
            .tabBarVisible(router.isTabBarVisible)
            
            ChatsListViewControllerWrapper(tabState: router)
                .ignoresSafeArea()
            .tabItem {
                Label(title: { Text(String.Constants.messages.localized()) },
                      icon: { Image.messageCircleIcon24 })
            }
            .tag(1)
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
                                               preRequestedAction: nil,
                                               sourceScreen: .domainsCollection)
            .ignoresSafeArea()
            .pullUpHandler(router)
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

final class HomeTabRouter: ObservableObject {
    @Published var isTabBarVisible: Bool = true
    @Published var tabViewSelection: Int = 0
    @Published var pullUp: ViewPullUpConfigurationType?
    @Published var walletViewNavPath: NavigationPath = NavigationPath()
    @Published var presentedNFT: NFTDisplayInfo?
    @Published var presentedDomain: DomainPresentationDetails?

    struct DomainPresentationDetails: Identifiable {
        var id: String { domain.name }
        
        let domain: DomainDisplayInfo
        let wallet: WalletEntity
    }
    
    let id: UUID = UUID()
    private var topViews = 0
    
    func currentPullUp(id: UUID) -> Binding<ViewPullUpConfigurationType?> {
        if topViews != 0 {
            guard self.id != id else {
                return Binding { nil } set: { newValue in }
            }
        } else {
            guard self.id == id else {
                return Binding { nil } set: { newValue in }
            }
        }
        return Binding { [weak self] in
            self?.pullUp
        } set: { [weak self] newValue in
            self?.pullUp = newValue
        }
    }
    
    func registerTopView(id: UUID) {
        topViews += 1
    }
    
    func unregisterTopView(id: UUID) {
        topViews -= 1
        topViews = max(0, topViews)
    }
    
    @MainActor
    func dismissPullUpMenu() async {
        if pullUp != nil {
            pullUp = nil
            await withSafeCheckedMainActorContinuation { completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    completion(Void())
                }
            }
        }
    }
    
    func popToRoot() {
        presentedNFT = nil
        presentedDomain = nil
        walletViewNavPath = .init()
    }
}

struct HomeTabPullUpHandlerModifier: ViewModifier {
    let tabRouter: HomeTabRouter
    let id = UUID()
    
    func body(content: Content) -> some View {
        content
            .viewPullUp(tabRouter.currentPullUp(id: id))
            .onAppear {
                tabRouter.registerTopView(id: id)
            }
            .onDisappear {
                tabRouter.unregisterTopView(id: id)
            }
    }
}

extension View {
    func pullUpHandler(_ tabRouter: HomeTabRouter) -> some View {
        modifier(HomeTabPullUpHandlerModifier(tabRouter: tabRouter))
    }
}
