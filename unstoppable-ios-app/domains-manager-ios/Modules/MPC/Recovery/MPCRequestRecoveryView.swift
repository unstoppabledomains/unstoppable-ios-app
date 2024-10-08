//
//  MPCRequestRecoveryView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 8.10.2024.
//

import SwiftUI

struct MPCRequestRecoveryView: View, ViewAnalyticsLogger {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var passwordInput: String = ""
    @State private var isLoading: Bool = false
    @State private var didRequestRecovery: Bool = false
    @State private var isPresentingForgotPasswordView: Bool = false

    var analyticsName: Analytics.ViewName { .mpcRequestRecovery }
    
    var body: some View {
        NavigationStack {
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
            .navigationDestination(isPresented: $didRequestRecovery) {
                MPCRecoveryRequestedView()
            }
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
        dismiss()
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
            didRequestRecovery = true
            isLoading = false
        }
    }
}

#Preview {
    MPCRequestRecoveryView()
}
