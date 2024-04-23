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
    let changeEmailCallback: ()->()
    @State private var input = ""
    
    var body: some View {
        VStack(spacing: isIPSE ? 16 : 24) {
            DismissIndicatorView()
            headerView()
            inputView()
            if case .passcode = dataType {
                MPCResendCodeButton(email: email)
            }
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
                .minimumScaleFactor(0.5)
                .foregroundStyle(Color.foregroundDefault)
            subtitleView()
        }
        .multilineTextAlignment(.center)
    }
    
    var title: String {
        switch dataType {
        case .passcode:
            "You’ve entered wrong verification code"
        case .password:
            "You’ve entered wrong password for MPC Wallet"
        }
    }
    
    @ViewBuilder
    func subtitleView() -> some View {
        switch dataType {
        case .passcode:
            subtitleTextView(String.Constants.pleaseTryAgain.localized())
        case .password:
            passwordSubtitleView()
        }
    }
    
    @ViewBuilder
    func subtitleTextView(_ text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 16))
            .foregroundStyle(Color.foregroundSecondary)
    }
    
    @ViewBuilder
    func passwordSubtitleView() -> some View {
        HStack {
            subtitleTextView(email)
            subtitleTextView("·")
            Button {
                UDVibration.buttonTap.vibrate()
                dismiss()
                changeEmailCallback()
            } label: {
                Text("Change")
                    .foregroundStyle(Color.foregroundAccent)
                    .font(.currentFont(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
        }
    }
    
    var subtitle: String {
        switch dataType {
        case .passcode:
            "You’ve entered wrong verification code"
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
                            rightViewType: .paste,
                            rightViewMode: .always,
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
    MPCActivateWalletEnterView(dataType: .password,
                               email: "qq@qq.qq",
                               confirmationCallback: { _ in },
                               changeEmailCallback: { })
}
