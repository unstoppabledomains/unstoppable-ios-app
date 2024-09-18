//
//  MPCActivateWalletEnterView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.04.2024.
//

import SwiftUI

struct MPCActivateWalletEnterView: View, ViewAnalyticsLogger {
    
    @Environment(\.dismiss) private var dismiss
    var analyticsName: Analytics.ViewName { dataType.analyticsName }
    
    let dataType: MPCActivateWalletEnterDataType
    let email: String
    let confirmationCallback: (String)->()
    var changeEmailCallback: EmptyCallback? = nil
    @State private var input = ""
    
    var body: some View {
        VStack(spacing: isIPSE ? 16 : 24) {
            DismissIndicatorView()
            headerView()
            inputView()
            if case .passcode(let resendAction) = dataType {
                MPCResendCodeButton(email: email, resendAction: resendAction)
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
            String.Constants.mpcWrongVerificationCodeMessage.localized()
        case .password:
            String.Constants.mpcWrongPasswordMessage.localizedMPCProduct()
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
            if let changeEmailCallback {
                subtitleTextView("·")
                Button {
                    UDVibration.buttonTap.vibrate()
                    dismiss()
                    changeEmailCallback()
                } label: {
                    Text(String.Constants.change.localized())
                        .foregroundStyle(Color.foregroundAccent)
                        .font(.currentFont(size: 16, weight: .medium))
                }
                .buttonStyle(.plain)
            }
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
        logButtonPressedAnalyticEvents(button: .confirm)
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
