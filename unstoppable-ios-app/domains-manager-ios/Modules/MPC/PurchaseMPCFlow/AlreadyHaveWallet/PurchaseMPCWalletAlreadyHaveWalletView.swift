//
//  PurchaseMPCWalletAlreadyHaveWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletAlreadyHaveWalletView: View {
    
    let email: String
    let callback: (PurchaseMPCWallet.AlreadyHaveWalletAction)->()
    
    var body: some View {
        ZStack {
            contentMessageView()
            VStack {
                Spacer()
                actionButtons()
            }
        }
        .padding()
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletAlreadyHaveWalletView {
    @ViewBuilder
    func contentMessageView() -> some View {
        VStack(spacing: 24) {
            Image.shieldKeyhole
                .resizable()
                .squareFrame(56)
                .foregroundStyle(Color.foregroundAccent)
            VStack(spacing: 16) {
                Text(String.Constants.mpcWalletAlreadyPurchasedTitle.localized())
                    .titleText()
                Text(String.Constants.mpcWalletAlreadyPurchasedSubtitle.localized())
                    .subtitleText()
            }
            .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func actionButtons() -> some View {
        VStack(spacing: 16) {
            changeEmailButton()
            importButton()
        }
    }
    
    @ViewBuilder
    func changeEmailButton() -> some View {
        UDButtonView(text: String.Constants.useDifferentEmail.localized(),
                     style: .large(.ghostPrimary)) {
            callback(.useDifferentEmail)
        }
    }
    
    @ViewBuilder
    func importButton() -> some View {
        UDButtonView(text: String.Constants.importMPCWalletTitle.localizedMPCProduct(),
                     style: .large(.raisedPrimary)) {
            callback(.importMPC)
        }
    }
}

#Preview {
    PurchaseMPCWalletAlreadyHaveWalletView(email: "qq@qq.qq",
                                           callback: { _ in })
}
