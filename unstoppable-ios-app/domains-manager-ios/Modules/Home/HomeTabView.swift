//
//  HomeTabView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct HomeTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                HomeWalletView()
            }
            .tabItem {
                Label(String.Constants.home.localized(),
                      systemImage: "house")
            }
            NavigationView {   
                HomeWalletView()
            }
                .tabItem {
                    Label(String.Constants.pluralNMessages.localized(2),
                          systemImage: "message.fill")
                }
        }
        .tint(.foregroundDefault)
    }
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = .foregroundSecondary
    }
}

#Preview {
    HomeTabView()
}
