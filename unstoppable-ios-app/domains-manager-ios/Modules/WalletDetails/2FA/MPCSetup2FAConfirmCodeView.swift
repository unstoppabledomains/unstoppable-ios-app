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
    var analyticsName: Analytics.ViewName { .setup2FAEnableConfirm }

    @State private var code: String = ""
    @State private var isLoading: Bool = false
    @State private var error: Error? = nil

    var body: some View {
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
}

private extension MPCSetup2FAConfirmCodeView {
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
                switch verificationPurpose {
                case .enable:
                    try await mpcWalletsService.confirm2FAEnabled(for: mpcMetadata,
                                                                  code: code)
                case .disable:
                    try await mpcWalletsService.disable2FA(for: mpcMetadata,
                                                           code: code)
                }
                didVerifyCode()
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func didVerifyCode() {
        switch verificationPurpose {    
        case .enable:
            appContext.toastMessageService.showToast(.enabled2FA, isSticky: false)
            tabRouter.walletViewNavPath.removeLast(2)
        case .disable:
            dismiss()
        }
    }
}

extension MPCSetup2FAConfirmCodeView {
    enum VerificationPurpose {
        case enable
        case disable
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
