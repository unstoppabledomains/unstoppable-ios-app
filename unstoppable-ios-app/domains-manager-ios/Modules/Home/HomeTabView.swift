//
//  HomeTabView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct HomeTabView: View {
    
    @StateObject private var tabState = TabStateManager()
    @StateObject var router = HomeTabRouter()
    let selectedWallet: WalletEntity

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
        .viewPullUp($router.pullUp)
    }
    
    init(selectedWallet: WalletEntity) {
        self.selectedWallet = selectedWallet
        UITabBar.appearance().unselectedItemTintColor = .foregroundSecondary
    }
}

#Preview {
    HomeTabView(selectedWallet: WalletEntity.mock().first!)
}

class TabStateManager: ObservableObject {
    @Published var isTabBarVisible: Bool = true
    @Published var tabViewSelection: Int = 0
}


class HomeTabRouter: ObservableObject {
    @Published var pullUp: ViewPullUpConfigurationType?
}

