//
//  MPCResetPasswordEnterPasswordView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.10.2024.
//

import SwiftUI

struct MPCResetPasswordEnterPasswordView: View, ViewAnalyticsLogger, MPCWalletPasswordValidator {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    @EnvironmentObject var viewModel: MPCResetPasswordViewModel
    var analyticsName: Analytics.ViewName { .mpcResetPasswordEnterPassword }

    let email: String
    @State private var passwordInput: String = ""
    @State private var passwordErrors: [MPCWalletPasswordValidationError] = []
    @State private var confirmPasswordInput: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var isLoading: Bool = false
    @State private var error: Error?

    var body: some View {
        contentView()
            .animation(.default, value: keyboardHeight)
            .displayError($error)
            .onChange(of: passwordInput, perform: { newValue in
                validatePasswordInput()
            })
            .onReceive(KeyboardService.shared.keyboardFramePublisher.receive(on: DispatchQueue.main)) { keyboardFrame in
                keyboardHeight = keyboardFrame.height
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButtonView {
                        logButtonPressedAnalyticEvents(button: .close)
                        dismiss()
                    }
                }
            }
    }
}

// MARK: - Private methods
private extension MPCResetPasswordEnterPasswordView {
    @ViewBuilder
    func contentView() -> some View {
            ScrollView {
                VStack(spacing: 8) {
                    VStack(spacing: 32) {
                        headerView()
                        VStack(spacing: 24) {
                            passwordInputView()
                            confirmPasswordInputView()
                        }
                    }
                    Spacer()
                    actionButtonContainerView()
                }
                .padding(.horizontal, 16)
            }
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.mpcResetPasswordTitle.localized())
                .titleText()
            Text(String.Constants.mpcResetPasswordSubtitle.localized())
                .subtitleText()
        }
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    func passwordInputView() -> some View {
        VStack(spacing: 8) {
            UDTextFieldView(text: $passwordInput,
                            placeholder: String.Constants.createPassword.localized(),
                            focusBehaviour: .activateOnAppear,
                            autocapitalization: .never,
                            autocorrectionDisabled: true,
                            isSecureInput: true,
                            isErrorState: isPasswordInErrorState)
            passwordRequirementsView()
        }
    }
    
    var isPasswordInErrorState: Bool {
        passwordErrors.contains(.tooLong)
    }
    
    @ViewBuilder
    func passwordRequirementsView() -> some View {
        VStack(spacing: 3) {
            ForEach(MPCWalletPasswordRequirements.allCases, id: \.self) { requirement in
                passwordRequirementView(requirement)
            }
        }
    }
    
    @ViewBuilder
    func passwordRequirementView(_ requirement: MPCWalletPasswordRequirements) -> some View {
        HStack(spacing: 8) {
            Circle()
                .squareFrame(4)
            Text(titleForRequirement(requirement, passwordErrors: passwordErrors))
                .font(.currentFont(size: 13))
            Spacer()
        }
        .foregroundStyle(foregroundStyleFor(requirement: requirement))
        .frame(minHeight: 20)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
    
    func foregroundStyleFor(requirement: MPCWalletPasswordRequirements) -> Color {
        if passwordInput.isEmpty {
            .foregroundSecondary
        } else if isPasswordRequirementMet(requirement, passwordErrors: passwordErrors) {
            .foregroundSuccess
        } else if isPasswordInErrorState && requirement == .length {
            .foregroundDanger
        } else {
            .foregroundSecondary
        }
    }
    
    @ViewBuilder
    func confirmPasswordInputView() -> some View {
        UDTextFieldView(text: $confirmPasswordInput,
                        placeholder: String.Constants.confirmPassword.localized(),
                        focusBehaviour: .default,
                        autocapitalization: .never,
                        autocorrectionDisabled: true,
                        isSecureInput: true)
    }
    
    func validatePasswordInput() {
        passwordErrors = validateWalletPassword(passwordInput)
    }
    
    var isActionButtonDisabled: Bool {
        !isValidPasswordEntered || passwordInput != confirmPasswordInput
    }
    
    var isValidPasswordEntered: Bool {
        passwordErrors.isEmpty
    }
    
    @ViewBuilder
    func actionButtonContainerView() -> some View {
//        VStack(spacing: 0) {
            continueButton()
//                .padding(.bottom, keyboardHeight + 16)
                .background(Color.black)
//        }
    }
    
    @ViewBuilder
    func continueButton() -> some View {
        UDButtonView(text: String.Constants.continue.localized(),
                     style: .large(.raisedPrimary),
                     isLoading: isLoading,
                     callback: actionButtonPressed)
        .disabled(isActionButtonDisabled)
    }
    
    func actionButtonPressed() {
        logButtonPressedAnalyticEvents(button: .continue)
        isLoading = true
        Task {
            do {
                try await mpcWalletsService.sendBootstrapCodeTo(email: email)
                viewModel.handleAction(.didEnterNewPassword(passwordInput))
            } catch {
                logAnalytic(event: .sendMPCBootstrapCodeError, parameters: [.error: error.localizedDescription])
                self.error = error
            }
            isLoading = false
        }
    }
}

#Preview {
    MPCResetPasswordEnterPasswordView(email: "test@example.com")
}
