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
    @State private var isWrongPasswordEntered: Bool = false
    @State private var path: [String] = []
    @State private var isPresentingForgotPasswordView: Bool = false
    @State private var error: Error?

    var analyticsName: Analytics.ViewName { .mpcRequestRecovery }
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 32) {
                    headerView()
                    passwordInputView()
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
                MPCForgotPasswordView(isModallyPresented: true)
            }
            .displayError($error)
            .animation(.default, value: isWrongPasswordEntered)
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
        VStack(spacing: 8) {
            UDTextFieldView(text: $passwordInput,
                            placeholder: String.Constants.password.localized(),
                            focusBehaviour: .activateOnAppear,
                            autocapitalization: .never,
                            autocorrectionDisabled: true,
                            isSecureInput: true,
                            isErrorState: isWrongPasswordEntered)
            if isWrongPasswordEntered {
                incorrectPasswordView()
            }
        }
    }
    
    @ViewBuilder
    func incorrectPasswordView() -> some View {
        HStack {
            Image.alertCircle
                .resizable()
                .squareFrame(12)
            Text(String.Constants.wrongPassword.localized())
                .font(.currentFont(size: 12, weight: .medium))
            Spacer()
        }
        .foregroundStyle(Color.foregroundDanger)
        .padding(.leading, 16)
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
        isWrongPasswordEntered = false
        
        Task {
            isLoading = true
            do {
                let email = try await mpcWalletsService.requestRecovery(password: passwordInput,
                                                                        by: mpcWalletMetadata)
                path.append(email)
            } catch MPCWalletError.wrongRecoveryPassword {
                self.isWrongPasswordEntered = true
            } catch {
                self.error = error
            }
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
