//
//  MPCSetup2FAEnableConfirmView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.10.2024.
//

import SwiftUI

struct MPCSetup2FAConfirmCodeView: View, ViewAnalyticsLogger {
    
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tabRouter: HomeTabRouter

    let mpcMetadata: MPCWalletMetadata
    let verificationPurpose: VerificationPurpose
    var navigationStyle: NavigationStyle = .push
    var analyticsName: Analytics.ViewName { .setup2FAEnableConfirm }

    @State private var code: String = ""
    @State private var isLoading: Bool = false
    @State private var error: Error? = nil

    var body: some View {
        switch navigationStyle {
        case .push:
            contentView()
        case .modal:
            NavigationStack {
                contentView()
                    .interactiveDismissDisabled()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            CloseButtonView(closeCallback: closeButtonPressed)
                        }
                    }
            }
        }
    }
}

private extension MPCSetup2FAConfirmCodeView {
    @ViewBuilder
    func contentView() -> some View {
        ScrollView {
            VStack(spacing: 32) {
                headerView()
                codeInputView()
                confirmButton()
            }
            .padding(.horizontal, 16)
        }
        .background(Color.backgroundDefault)
        .displayError($error)
    }

    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.enable2FAConfirmTitle.localized())
                .titleText()
            Text(String.Constants.enable2FAConfirmSubtitle.localized())
                .subtitleText()
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    func codeInputView() -> some View {
        UDTextFieldView(text: $code,
                        placeholder: "",
                        hint: String.Constants.verificationCode.localized(),
                        rightViewType: .paste,
                        rightViewMode: .always,
                        focusBehaviour: .activateOnAppear,
                        keyboardType: .alphabet,
                        autocapitalization: .characters,
                        textContentType: .oneTimeCode,
                        autocorrectionDisabled: true)
    }

    @ViewBuilder
    func confirmButton() -> some View {
        UDButtonView(text: String.Constants.verify.localized(),
                     style: .large(.raisedPrimary),
                     isLoading: isLoading,
                     callback: {
                logButtonPressedAnalyticEvents(button: .verify)
                verifyCode()
            })
    }

    func verifyCode() {
        isLoading = true
        Task {
            do {
                let code = self.code
                switch verificationPurpose {
                case .enable:
                    try await mpcWalletsService.confirm2FAEnabled(for: mpcMetadata,
                                                                  code: code)
                case .disable:
                    try await mpcWalletsService.disable2FA(for: mpcMetadata,
                                                           code: code)
                case .enterCode:
                    Void()
                }
                didVerifyCode(code)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func didVerifyCode(_ code: String) {
        switch verificationPurpose {
        case .enable:
            appContext.toastMessageService.showToast(.enabled2FA, isSticky: false)
            tabRouter.walletViewNavPath.removeLast(2)
        case .disable:
            dismiss()
        case .enterCode(let callback):
            callback(code)
            dismiss()
        }
    }

    func closeButtonPressed() {
        if case .enterCode(let callback) = verificationPurpose {
            callback(nil)
        }
        dismiss()
    }   
}

extension MPCSetup2FAConfirmCodeView {
    enum VerificationPurpose {
        case enable
        case disable
        case enterCode(callback: (String?) -> Void)
    }

    enum NavigationStyle {
        case push
        case modal
    }
}

#Preview {
    let wallet = MockEntitiesFabric.Wallet.mockMPC()
    let mpcMetadata = wallet.udWallet.mpcMetadata!
    
    return NavigationStack {
        MPCSetup2FAConfirmCodeView(mpcMetadata: mpcMetadata,
                                     verificationPurpose: .enable)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image(systemName: "arrow.left")
            }
        }
    }
}
