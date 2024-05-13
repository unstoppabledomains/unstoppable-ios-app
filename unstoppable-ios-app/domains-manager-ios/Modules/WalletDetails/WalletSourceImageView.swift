//
//  WalletSourceImageView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.05.2024.
//

import SwiftUI

struct WalletSourceImageView: View {
    
    let displayInfo: WalletDisplayInfo
    
    private var isCenteredImage: Bool {
        switch displayInfo.source {
        case .locallyGenerated, .external:
            return false
        case .imported, .mpc:
            return true
        }
    }
    
    var body: some View {
        Image(uiImage: displayInfo.source.displayIcon)
            .resizable()
            .squareFrame(isCenteredImage ? 40 : 80)
            .padding(isCenteredImage ? 20 : 0)
            .background(Color.backgroundMuted2)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
    }
}

#Preview {
    WalletSourceImageView(displayInfo: MockEntitiesFabric.Wallet.mockEntities()[0].displayInfo)
}