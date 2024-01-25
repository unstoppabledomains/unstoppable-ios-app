//
//  HomeTabView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct HomeTabView: View {
    
    @StateObject private var tabState: TabStateManager
    @StateObject var router: HomeTabRouter
    let selectedWallet: WalletEntity
    private let id: UUID

    var body: some View {
        TabView(selection: $tabState.tabViewSelection) {
            HomeWalletView(viewModel: .init(selectedWallet: selectedWallet))
            .tabItem {
                Label(title: { Text(String.Constants.home.localized()) },
                      icon: { Image.homeLineIcon })
            }
            .tag(0)
            .tabBarVisible(tabState.isTabBarVisible)
            
            HomeWalletView(viewModel: .init(selectedWallet: selectedWallet))
            .tabItem {
                Label(title: { Text(String.Constants.messages.localized()) },
                      icon: { Image.messageCircleIcon24 })
            }
            .tag(1)
        }
        .tint(.foregroundDefault)
        .environmentObject(tabState)
        .environmentObject(router)
        .viewPullUp(router.currentPullUp(id: id))
    }
    
    init(selectedWallet: WalletEntity,
         tabRouter: HomeTabRouter) {
        let tabState = TabStateManager()
        self._tabState = StateObject(wrappedValue: tabState)
        self._router = StateObject(wrappedValue: tabRouter)
        self.selectedWallet = selectedWallet
        self.id = tabRouter.id
        UITabBar.appearance().unselectedItemTintColor = .foregroundSecondary
    }
}

#Preview {
    HomeTabView(selectedWallet: MockEntitiesFabric.Wallet.mockEntities().first!, tabRouter: HomeTabRouter())
}

class TabStateManager: ObservableObject {
    @Published var isTabBarVisible: Bool = true
    @Published var tabViewSelection: Int = 0
}


class HomeTabRouter: ObservableObject {
    @Published var pullUp: ViewPullUpConfigurationType?
    
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
