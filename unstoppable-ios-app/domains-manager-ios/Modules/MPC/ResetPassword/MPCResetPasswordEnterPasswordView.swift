//
//  MPCResetPasswordEnterPasswordView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.10.2024.
//

import SwiftUI

struct MPCResetPasswordEnterPasswordView: View, ViewAnalyticsLogger, MPCWalletPasswordValidator {
    
    @Environment(\.dismiss) var dismiss
    var analyticsName: Analytics.ViewName { .mpcResetPasswordEnterPassword }
    
    @State private var passwordInput: String = ""
    @State private var passwordErrors: [MPCWalletPasswordValidationError] = []
    @State private var confirmPasswordInput: String = ""
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        NavigationStack {
            contentView()
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
}

// MARK: - Private methods
private extension MPCResetPasswordEnterPasswordView {
    @ViewBuilder
    func contentView() -> some View {
        ZStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerView()
                    VStack(spacing: 24) {
                        passwordInputView()
                        confirmPasswordInputView()
                    }
                }
                .padding(.horizontal, 16)
            }
            
            actionButtonContainerView()
                .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.mpcRequestRecoveryTitle.localized())
                .titleText()
            Text(String.Constants.mpcRequestRecoverySubtitle.localized())
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
        VStack(spacing: 0) {
            Spacer()
            Rectangle()
                .frame(height: 16)
                .foregroundStyle(LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top))
            continueButton()
                .padding(.bottom, keyboardHeight + 16)
                .padding(.horizontal, 16)
                .background(Color.black)
        }
    }
    
    @ViewBuilder
    func continueButton() -> some View {
        UDButtonView(text: String.Constants.continue.localized(),
                     style: .large(.raisedPrimary),
                     callback: actionButtonPressed)
        .disabled(isActionButtonDisabled)
    }
    
    func actionButtonPressed() {
        logButtonPressedAnalyticEvents(button: .continue)
//        let password = passwordInput
//        passwordCallback(password)
    }
}

#Preview {
    MPCResetPasswordEnterPasswordView()
}
