//
//  HomeWalletProfileSelectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import SwiftUI

struct HomeWalletProfileSelectionView: View {
    
    let wallet: WalletEntity
    let domainNamePressedCallback: MainActorCallback

    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            domainNamePressedCallback()
        } label: {
            HStack(spacing: 0) {
                Text(getCurrentTitle())
                    .font(.currentFont(size: 16, weight: .medium))
                Image.chevronGrabberVertical
                    .squareFrame(24)
            }
            .foregroundStyle(Color.foregroundSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    
    func getCurrentTitle() -> String {
        if let rrDomain = wallet.rrDomain {
            return rrDomain.name
        }
        return wallet.displayName
    }
    
}
