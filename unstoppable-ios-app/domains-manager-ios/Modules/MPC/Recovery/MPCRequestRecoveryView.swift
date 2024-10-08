//
//  MPCRequestRecoveryView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 8.10.2024.
//

import SwiftUI

struct MPCRequestRecoveryView: View, ViewAnalyticsLogger {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.mpcWalletsService) private var mpcWalletsService

    let mpcWalletMetadata: MPCWalletMetadata
    @State private var passwordInput: String = ""
    @State private var isLoading: Bool = false
    @State private var path: [String] = []
    @State private var isPresentingForgotPasswordView: Bool = false

    var analyticsName: Analytics.ViewName { .mpcRequestRecovery }
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 32) {
                    headerView()
                    passwordInputView()
                    Spacer()
                    VStack(spacing: 16) {
                        forgotPasswordButtonView()
                        confirmButtonView()
                    }
                }
                .padding(.horizontal, 16)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButtonView(closeCallback: closeButtonPressed)
                }
            }
            .sheet(isPresented: $isPresentingForgotPasswordView) {
                MPCForgotPasswordView()
                    .padding(.top, 32)
            }
            .navigationDestination(for: String.self, destination: { email in
                MPCRecoveryRequestedView(email: email,
                                         closeCallback: close)
            })
        }
    }
    
}

// MARK: - Private methods
private extension MPCRequestRecoveryView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 20) {
            Image.folderIcon
                .resizable()
                .squareFrame(56)
                .foregroundStyle(Color.foregroundSecondary)
            VStack(spacing: 16) {
                Text(String.Constants.mpcRequestRecoveryTitle.localized())
                    .titleText()
                Text(String.Constants.mpcRequestRecoverySubtitle.localized())
                    .subtitleText()
            }
            .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func passwordInputView() -> some View {
        UDTextFieldView(text: $passwordInput,
                        placeholder: String.Constants.password.localized(),
                        focusBehaviour: .activateOnAppear,
                        autocapitalization: .never,
                        autocorrectionDisabled: true,
                        isSecureInput: true)
    }
    
    @ViewBuilder
    func forgotPasswordButtonView() -> some View {
        UDButtonView(text: String.Constants.forgotPasswordTitle.localized(),
                     style: .large(.ghostPrimary),
                     callback: forgotPasswordButtonPressed)
    }
    
    @ViewBuilder
    func confirmButtonView() -> some View {
        UDButtonView(text: String.Constants.confirm.localized(),
                     style: .large(.raisedPrimary),
                     isLoading: isLoading,
                     callback: confirmButtonPressed)
    }
}

// MARK: - Private methods
private extension MPCRequestRecoveryView {
    func closeButtonPressed() {
        logButtonPressedAnalyticEvents(button: .close)
        close()
    }
    
    func forgotPasswordButtonPressed() {
        logButtonPressedAnalyticEvents(button: .forgotPassword)
        isPresentingForgotPasswordView = true
    }
    
    func confirmButtonPressed() {
        logButtonPressedAnalyticEvents(button: .confirm)
        
        Task {
            isLoading = true
            await Task.sleep(seconds: 1)
            let email = try await mpcWalletsService.requestRecovery(password: passwordInput,
                                                                    by: mpcWalletMetadata)
            path.append(email)
            isLoading = false
        }
    }
    
    func close() {
        dismiss()
    }
}

#Preview {
    MPCRequestRecoveryView(mpcWalletMetadata: MPCWalletMetadata(provider: MPCWalletProvider.fireblocksUD,
                                                                metadata: nil))
}
