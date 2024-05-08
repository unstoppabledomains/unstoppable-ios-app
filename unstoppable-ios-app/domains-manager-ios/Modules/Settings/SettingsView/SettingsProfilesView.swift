//
//  SettingsProfilesView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2024.
//

import SwiftUI

struct SettingsProfilesView: View {
    
    let profiles: [UserProfile]
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(profiles, id: \.id) { profile in
                Button {
//                    logButtonPressedAnalyticEvents(button: .buyDomainTile)
                    UDVibration.buttonTap.vibrate()
//                    buyDomainCallback()
                } label: {
                    SettingsProfileTileView(profile: profile)
                }
                .buttonStyle(.plain)
            }
        }
    }
}


#Preview {
    SettingsProfilesView(profiles: [MockEntitiesFabric.Profile.createWalletProfile()])
}
