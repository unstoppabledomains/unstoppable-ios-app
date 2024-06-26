//
//  PurchaseMPCWalletAlreadyHaveWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletAlreadyHaveWalletView: View, ViewAnalyticsLogger {
    
    let analyticsName: Analytics.ViewName
    let email: String
    let callback: (PurchaseMPCWallet.AlreadyHaveWalletAction)->()
    
    var body: some View {
        ZStack {
            contentMessageView()
                .padding(.bottom, isIPSE ? 60 : 0)
            VStack {
                Spacer()
                actionButtons()
            }
        }
        .padding()
        .trackAppearanceAnalytics(analyticsLogger: self)
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
                Text(String.Constants.mpcWalletAlreadyPurchasedTitle.localizedMPCProduct())
                    .titleText()
                HStack {
                    Text(String.Constants.email.localized() + ":")
                        .subtitleText()
                    Text(email)
                        .textAttributes(color: .foregroundDefault,
                                        fontSize: 16,
                                        fontWeight: .medium)
                }
                .lineLimit(1)
            }
            Text(String.Constants.mpcWalletAlreadyPurchasedSubtitle.localized())
                .subtitleText()
        }
        .multilineTextAlignment(.center)
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
            logButtonPressedAnalyticEvents(button: .useDifferentEmail)
            callback(.useDifferentEmail)
        }
    }
    
    @ViewBuilder
    func importButton() -> some View {
        UDButtonView(text: String.Constants.importMPCWalletTitle.localizedMPCProduct(),
                     style: .large(.raisedPrimary)) {
            logButtonPressedAnalyticEvents(button: .importWallet)
            callback(.importMPC)
        }
    }
}

#Preview {
    PurchaseMPCWalletAlreadyHaveWalletView(analyticsName: .unspecified,
                                           email: "qq@qq.qq",
                                           callback: { _ in })
}
