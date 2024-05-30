//
//  PurchaseMPCWalletTakeoverView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverCredentialsView: View, UserDataValidator, MPCWalletPasswordValidator {
    
    @Environment(\.ecomPurchaseMPCWalletService) private var ecomPurchaseMPCWalletService

    var purchaseEmail: String?
    let credentialsCallback: (MPCActivateCredentials)->()
    @State private var emailInput: String = ""
    @State private var emailConfirmationInput: String = ""
    @State private var passwordInput: String = ""
    @State private var passwordErrors: [MPCWalletPasswordValidationError] = []
    @State private var confirmPasswordInput: String = ""
    @State private var isEmailFocused = true
    @State private var emailInUseState: EmailInUseVerificationState = .unverified
    @State private var didSetupPurchaseEmail = false
    @StateObject private var debounceObject = DebounceObject()

    var body: some View {
        ScrollView {
            VStack(spacing: isIPSE ? 16 : 32) {
                headerView()
                VStack(alignment: .leading, spacing: 16) {
                    emailInputView()
                    emailConfirmationInputView()
                    inputSeparatorView()
                    passwordInputView()
                    confirmPasswordInputView()
                }
                actionButtonView()
                Spacer()
            }
        }
        .scrollIndicators(.hidden)
        .padding()
        .onChange(of: passwordInput, perform: { newValue in
            validatePasswordInput()
        })
        .animation(.default, value: UUID())
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverCredentialsView {
    func onAppear() {
        validatePasswordInput()
        setupPurchaseEmail()
        checkIfEmailAlreadyInUseIfNeeded()
    }
    
    func setupPurchaseEmail() {
        guard !didSetupPurchaseEmail else { return }
        
        didSetupPurchaseEmail = true
        emailInput = purchaseEmail ?? ""
        debounceObject.text = emailInput
    }
    
    func validatePasswordInput() {
        passwordErrors = validateWalletPassword(passwordInput)
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.setup.localized())
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
            Text(String.Constants.mpcTakeoverCredentialsSubtitle.localized())
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func emailInputView() -> some View {
        VStack(spacing: 8) {
            UDTextFieldView(text: $debounceObject.text,
                            placeholder: "name@mail.com",
                            hint: String.Constants.emailAssociatedWithWallet.localized(),
                            focusBehaviour: .activateOnAppear,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            autocorrectionDisabled: true,
                            isErrorState: emailVerificationError != nil,
                            focusedStateChangedCallback: { isFocused in
                isEmailFocused = isFocused
                if !isFocused {
                    checkIfEmailAlreadyInUseIfNeeded()
                }
            })
            .onChange(of: debounceObject.debouncedText) { text in
                emailInput = text.trimmedSpaces
                checkIfEmailAlreadyInUseIfNeeded()
            }
            if let emailVerificationError {
                incorrectEmailIndicatorView(error: emailVerificationError)
            }
        }
    }
    
    @ViewBuilder
    func emailConfirmationInputView() -> some View {
        if shouldShowEmailConfirmation {
            UDTextFieldView(text: $emailConfirmationInput,
                            placeholder: String.Constants.confirmEmail.localized(),
                            focusBehaviour: .default,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            autocorrectionDisabled: true)
        }
    }
    
    @ViewBuilder
    func inputSeparatorView() -> some View {
        if shouldShowEmailConfirmation {
            HomeExploreSeparatorView()
        }
    }
    
    var shouldShowEmailConfirmation: Bool {
        purchaseEmail != emailInput
    }
    
    var emailVerificationError: EmailVerificationError? {
        if case .inUse = emailInUseState {
            return .alreadyInUse
        } else if !isEmailFocused && !isValidEmailEntered {
            return .incorrectFormat
        }
        return nil
    }
    
    @ViewBuilder
    func incorrectEmailIndicatorView(error: EmailVerificationError) -> some View {
        HStack(spacing: 8) {
            Image.alertCircle
                .resizable()
                .squareFrame(16)
            Text(error.title)
                .font(.currentFont(size: 12, weight: .medium))
            Spacer()
        }
        .foregroundStyle(Color.foregroundDanger)
        .padding(.leading, 16)
    }
    
    @ViewBuilder
    func passwordInputView() -> some View {
        VStack(spacing: 8) {
            UDTextFieldView(text: $passwordInput,
                            placeholder: String.Constants.createPassword.localized(),
                            focusBehaviour: .default,
                            autocapitalization: .never,
                            autocorrectionDisabled: true,
                            isSecureInput: true,
                            isErrorState: isPasswordInErrorState,
                            focusedStateChangedCallback: { isFocused in
                if !isFocused {
                    checkIfEmailAlreadyInUseIfNeeded()
                }
            })
            passwordRequirementsView()
        }
    }
    
    var isPasswordInErrorState: Bool {
        passwordErrors.contains(.tooLong)
    }
    
    @ViewBuilder
    func passwordRequirementsView() -> some View {
        VStack(spacing: 3) {
            ForEach(PasswordRequirements.allCases, id: \.self) { requirement in
                passwordRequirementView(requirement)
            }
        }
    }
    
    @ViewBuilder
    func passwordRequirementView(_ requirement: PasswordRequirements) -> some View {
        HStack(spacing: 8) {
            Circle()
                .squareFrame(4)
            Text(titleFor(requirement: requirement))
                .font(.currentFont(size: 13))
            Spacer()
        }
        .foregroundStyle(foregroundStyleFor(requirement: requirement))
        .frame(minHeight: 20)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
    
    func foregroundStyleFor(requirement: PasswordRequirements) -> Color {
        if isPasswordRequirementMet(requirement) {
            .foregroundSuccess
        } else if isPasswordInErrorState && requirement == .length {
            .foregroundDanger
        } else {
            .foregroundSecondary
        }
    }
    
    func isPasswordRequirementMet(_ requirement: PasswordRequirements) -> Bool {
        switch requirement {
        case .length:
            !passwordErrors.contains(.tooShort) && !passwordErrors.contains(.tooLong)
        case .oneNumber:
            !passwordErrors.contains(.missingNumber)
        case .specialChar:
            !passwordErrors.contains(.missingSpecialCharacter)
        }
    }
    
    enum PasswordRequirements: CaseIterable {
        case length
        case oneNumber
        case specialChar
    }
    
    func titleFor(requirement: PasswordRequirements) -> String {
        switch requirement {
        case .length:
            if passwordErrors.contains(.tooLong) {
                String.Constants.mpcPasswordValidationTooLongTitle.localized(minMPCWalletPasswordLength, maxMPCWalletPasswordLength)
            } else {
                String.Constants.mpcPasswordValidationLengthTitle.localized(minMPCWalletPasswordLength)
            }
        case .oneNumber:
            String.Constants.mpcPasswordValidationNumberTitle.localized()
        case .specialChar:
            String.Constants.mpcPasswordValidationSpecialCharTitle.localized()
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
    
    var isActionButtonDisabled: Bool {
        !isValidEmailEntered || !isValidPasswordEntered || passwordInput != confirmPasswordInput || !isEmailConfirmed || !isVerifiedEmailEntered
    }
    
    var isValidEmailEntered: Bool {
        isEmailValid(emailInput)
    }
    
    var isValidPasswordEntered: Bool {
        passwordErrors.isEmpty
    }
    
    var isVerifiedEmailEntered: Bool {
        if case .verified(let value) = emailInUseState {
            return emailInput == value
        }
        return false
    }
    
    var isEmailConfirmed: Bool {
        if let purchaseEmail,
           purchaseEmail == emailInput {
            return true
        }
        return emailInput == emailConfirmationInput
    }
    
    @ViewBuilder
    func actionButtonView() -> some View {
        UDButtonView(text: String.Constants.continue.localized(),
                     style: .large(.raisedPrimary),
                     callback: actionButtonPressed)
        .disabled(isActionButtonDisabled)
    }
    
    func actionButtonPressed() {
        let email = emailInput
        let password = passwordInput
        let credentials = MPCActivateCredentials(email: email, password: password)
        credentialsCallback(credentials)
    }
    
    enum EmailVerificationError {
        case incorrectFormat
        case alreadyInUse
        
        var title: String {
            switch self {
            case .incorrectFormat:
                return String.Constants.incorrectEmailFormat.localized()
            case .alreadyInUse:
                return String.Constants.mpcWalletEmailInUseMessage.localized()
            }
        }
    }
    
    func checkIfEmailAlreadyInUseIfNeeded() {
        guard !isVerifiedEmailEntered, 
            isValidPasswordEntered else { return }
        
        if case .inUse = emailInUseState {
            emailInUseState = .unverified
        }
        Task {
            let email = emailInput
            let password = passwordInput
            let credentials = MPCTakeoverCredentials(email: email, password: password)
            let isValid = try await ecomPurchaseMPCWalletService.validateCredentialsForTakeover(credentials: credentials)
            
            if isValid {
                emailInUseState = .verified(email)
            } else {
                emailInUseState = .inUse
            }
        }
    }
    
    enum EmailInUseVerificationState {
        case unverified
        case verified(String)
        case inUse
    }
}

#Preview {
    PurchaseMPCWalletTakeoverCredentialsView(purchaseEmail: "qq@qq.qq",
                                             credentialsCallback: { _ in })
}
