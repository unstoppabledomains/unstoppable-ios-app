//
//  SettingsProfilesView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2024.
//

import SwiftUI

struct SettingsProfilesView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    @EnvironmentObject private var tabRouter: HomeTabRouter

    let profiles: [UserProfile]
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(profiles, id: \.id) { profile in
                Button {
                    logButtonPressedAnalyticEvents(button: .walletInList)
                    UDVibration.buttonTap.vibrate()
                    switch profile {
                    case .wallet(let wallet):
                        tabRouter.walletViewNavPath.append(.walletDetails(wallet))
                    case .webAccount:
                        return
                    }
                } label: {
                    SettingsProfileTileView(profile: profile)
                }
                .buttonStyle(.plain)
            }
        }
    }
}


#Preview {
    SettingsProfilesView(profiles: [MockEntitiesFabric.Profile.createWalletProfile(),
                                    MockEntitiesFabric.Profile.createExternalWalletProfile(),
                                    MockEntitiesFabric.Profile.createWebAccountProfile(),
                                    ])
}
