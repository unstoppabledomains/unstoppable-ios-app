//
//  HomeTabView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct HomeTabView: View {
    
    @StateObject private var tabState = TabStateManager()
    let selectedWallet: WalletEntity

    var body: some View {
        TabView {
            HomeWalletView(viewModel: .init(selectedWallet: selectedWallet))
            .tabItem {
                Label(title: { Text(String.Constants.home.localized()) },
                      icon: { Image.homeLineIcon })
            }
            .tabBarVisible(tabState.isTabBarVisible)
            
            NavigationView {
                HomeWalletView(viewModel: .init(selectedWallet: selectedWallet))
            }
            .tabItem {
                Label(title: { Text(String.Constants.messages.localized()) },
                      icon: { Image.messageCircleIcon24 })
            }
        }
        .tint(.foregroundDefault)
        .environmentObject(tabState)
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
}

