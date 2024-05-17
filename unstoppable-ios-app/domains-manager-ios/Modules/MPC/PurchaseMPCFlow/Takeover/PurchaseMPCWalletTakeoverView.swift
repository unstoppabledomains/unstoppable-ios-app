//
//  PurchaseMPCWalletTakeoverView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverView: View, UserDataValidator {
    
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    @Environment(\.ecomPurchaseMPCWalletService) private var ecomPurchaseMPCWalletService

    let credentialsCallback: (MPCActivateCredentials)->()
    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""
    @State private var confirmPasswordInput: String = ""
    @State private var isLoading = false
    @State private var isEmailFocused = true
    @State private var error: Error?
    
    var body: some View {
        ScrollView {
            VStack(spacing: isIPSE ? 16 : 32) {
                headerView()
                VStack(alignment: .leading, spacing: 16) {
                    emailInputView()
                    passwordInputView()
                    confirmPasswordInputView()
                }
                actionButtonView()
                Spacer()
            }
        }
        .scrollDisabled(true)
        .padding()
        .displayError($error)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text("Setup Unstoppable Wallet")
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
//            Text(String.Constants.importMPCWalletSubtitle.localizedMPCProduct())
//                .font(.currentFont(size: 16))
//                .foregroundStyle(Color.foregroundSecondary)
//                .minimumScaleFactor(0.6)
//                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func emailInputView() -> some View {
        VStack(spacing: 8) {
            UDTextFieldView(text: $emailInput,
                            placeholder: "name@mail.com",
                            hint: String.Constants.emailAssociatedWithWallet.localized(),
                            focusBehaviour: .activateOnAppear,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            autocorrectionDisabled: true,
                            isErrorState: shouldShowEmailError,
                            focusedStateChangedCallback: { isFocused in
                isEmailFocused = isFocused
            })
            if shouldShowEmailError {
                incorrectEmailIndicatorView()
            }
        }
    }
    
    var shouldShowEmailError: Bool {
        !isEmailFocused && !isValidEmailEntered
    }
    
    @ViewBuilder
    func incorrectEmailIndicatorView() -> some View {
        HStack(spacing: 8) {
            Image.alertCircle
                .resizable()
                .squareFrame(16)
            Text(String.Constants.incorrectEmailFormat.localized())
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
                            isSecureInput: true)
            passwordRequirementsView()
        }
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
            Text(requirement.title)
                .font(.currentFont(size: 13))
            Spacer()
        }
        .foregroundStyle(Color.foregroundSecondary)
        .frame(minHeight: 20)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
    
    enum PasswordRequirements: CaseIterable {
        case minLength
        case oneNumber
        case specialChar
        
        var title: String {
            switch self {
            case .minLength:
                return "Minimum 12 characters"
            case .oneNumber:
                return "At least one number"
            case .specialChar:
                return "At least one special character (e.g. -!&*)"
            }
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
        !isValidEmailEntered || !isValidPasswordEntered || passwordInput != confirmPasswordInput
    }
    
    var isValidEmailEntered: Bool {
        isEmailValid(emailInput)
    }
    
    var isValidPasswordEntered: Bool {
        passwordInput.isEmpty
    }
    
    @ViewBuilder
    func actionButtonView() -> some View {
        UDButtonView(text: String.Constants.continue.localized(),
                     style: .large(.raisedPrimary),
                     isLoading: isLoading,
                     callback: actionButtonPressed)
        .disabled(isActionButtonDisabled)
    }
    
    func actionButtonPressed() {
        Task {
            isLoading = true
            do {
                let email = emailInput
                let password = passwordInput
                let credentials = MPCActivateCredentials(email: email, password: password)
                try await ecomPurchaseMPCWalletService.runTakeover(credentials: credentials)
                // Send email action
                try await mpcWalletsService.sendBootstrapCodeTo(email: email)
                credentialsCallback(credentials)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
}

#Preview {
    PurchaseMPCWalletTakeoverView(credentialsCallback: { _ in })
}
