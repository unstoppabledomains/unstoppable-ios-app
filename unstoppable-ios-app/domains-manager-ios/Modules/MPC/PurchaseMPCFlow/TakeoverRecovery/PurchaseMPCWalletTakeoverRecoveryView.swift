//
//  PurchaseMPCWalletTakeoverRecoveryView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverRecoveryView: View {
    
    let email: String
    let confirmCallback: (Bool)->()
    
    var body: some View {
        VStack(spacing: isIPSE ? 16 : 32) {
            headerView()
            illustrationView()
            Spacer()
            actionsButtonView()
        }
        .padding()
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverRecoveryView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.mpcTakeoverRecoveryTitle.localized())
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
            subtitleView()
        }
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    func subtitleView() -> some View {
        VStack(spacing: 0) {
            Text(String.Constants.mpcTakeoverRecoverySubtitle.localized())
                .foregroundStyle(Color.foregroundSecondary)
                .minimumScaleFactor(0.6)
            Text(email)
                .foregroundStyle(Color.foregroundDefault)
                .lineLimit(1)
        }
        .font(.currentFont(size: 16))
    }
    
    @ViewBuilder
    func illustrationView() -> some View {
        Image.mpcWalletRecoveryIllustration
            .resizable()
            .padding(.horizontal, 16)
            .aspectRatio(329 / 341, contentMode: .fit)
    }
    
    @ViewBuilder
    func actionsButtonView() -> some View {
        VStack(spacing: 16) {
            dontUseRecoveryButton()
            useRecoveryButton()
        }
    }
    
    @ViewBuilder
    func useRecoveryButton() -> some View {
        UDButtonView(text: String.Constants.sendMeRecoveryLink.localized(),
                     style: .large(.raisedPrimary),
                     callback: useRecoveryButtonPressed)
    }
    
    func useRecoveryButtonPressed() {
        confirmCallback(true)
    }
    
    @ViewBuilder
    func dontUseRecoveryButton() -> some View {
        UDButtonView(text: String.Constants.dontSendMeRecoveryLink.localized(),
                     style: .large(.ghostDanger),
                     callback: dontUseRecoveryButtonPressed)
    }
    
    func dontUseRecoveryButtonPressed() {
        confirmCallback(false)
    }
}

#Preview {
    PurchaseMPCWalletTakeoverRecoveryView(email: "qq@qq.qq",
                                          confirmCallback: { _ in })
}
