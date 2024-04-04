//
//  WalletTransactionTypeIndicatorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.04.2024.
//

import SwiftUI

struct WalletTransactionTypeIndicatorView: View {
    
    let type: WalletTransactionDisplayInfo.TransactionType
    
    var body: some View {
        icon
            .resizable()
            .squareFrame(16)
            .padding(4)
            .foregroundStyle(Color.white)
            .background(background)
            .clipShape(Circle())
    }
}

// MARK: - Private methods
private extension WalletTransactionTypeIndicatorView {
    var icon: Image {
        if type.isDeposit {
            .arrowBottom
        } else {
            .paperPlaneTopRightSend
        }
    }
    
    var background: Color {
        if type.isDeposit {
            .backgroundSuccessEmphasis
        } else {
            .backgroundAccentEmphasis
        }
    }
}

#Preview {
    WalletTransactionTypeIndicatorView(type: .nftWithdrawal)
}
