//
//  HomeTabView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct HomeTabView: View {
    
    let selectedWallet: WalletEntity
    
    var body: some View {
        TabView {
            NavigationView {
                HomeWalletView(viewModel: .init(selectedWallet: selectedWallet))
            }
            .tabItem {
                Label(title: { Text(String.Constants.home.localized()) },
                      icon: { Image.homeLineIcon })
            }
            NavigationView {
                HomeWalletView(viewModel: .init(selectedWallet: selectedWallet))
            }
            .tabItem {
                Label(title: { Text(String.Constants.messages.localized()) },
                      icon: { Image.messageCircleIcon24 })
            }
        }
        .tint(.foregroundDefault)
    }
    
    init(selectedWallet: WalletEntity) {
        self.selectedWallet = selectedWallet
        UITabBar.appearance().unselectedItemTintColor = .foregroundSecondary
    }
}

#Preview {
    HomeTabView(selectedWallet: WalletEntity.mock().first!)
}
