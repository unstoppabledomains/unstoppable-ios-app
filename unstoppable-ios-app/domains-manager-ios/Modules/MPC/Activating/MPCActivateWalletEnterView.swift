//
//  MPCActivateWalletEnterView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.04.2024.
//

import SwiftUI

struct MPCActivateWalletEnterView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let dataType: MPCActivateWalletEnterDataType
    let email: String
    let confirmationCallback: (String)->()
    @State private var input = ""
    
    var body: some View {
        VStack(spacing: 24) {
            DismissIndicatorView()
            headerView()
            inputView()
            actionButtonView()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Private methods
private extension MPCActivateWalletEnterView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.currentFont(size: 22, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
            Text(email)
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
        }
        .multilineTextAlignment(.center)
    }
    
    var title: String {
        switch dataType {
        case .passcode:
            "You’ve entered wrong passcode for MPC Wallet"
        case .password:
            "You’ve entered wrong password for MPC Wallet"
        }
    }
    
    @ViewBuilder
    func inputView() -> some View {
        switch dataType {
        case .passcode:
            UDTextFieldView(text: $input,
                            placeholder: "",
                            hint: String.Constants.verificationCode.localized(),
                            focusBehaviour: .activateOnAppear,
                            autocapitalization: .characters,
                            autocorrectionDisabled: true)
        case .password:
            UDTextFieldView(text: $input,
                            placeholder: "",
                            hint: String.Constants.password.localized(),
                            focusBehaviour: .activateOnAppear,
                            autocapitalization: .never,
                            autocorrectionDisabled: true,
                            isSecureInput: true)
        }
    }
    
    @ViewBuilder
    func actionButtonView() -> some View {
        UDButtonView(text: String.Constants.confirm.localized(),
                     style: .large(.raisedPrimary),
                     callback: actionButtonPressed)
    }
    
    func actionButtonPressed() {
        dismiss()
        confirmationCallback(input)
    }
}

#Preview {
    MPCActivateWalletEnterView(dataType: .passcode,
                               email: "qq@qq.qq",
                               confirmationCallback: { _ in })
}

enum MPCActivateWalletEnterDataType: String, Hashable, Identifiable {
    var id: String { rawValue }
    
    case passcode
    case password
}
