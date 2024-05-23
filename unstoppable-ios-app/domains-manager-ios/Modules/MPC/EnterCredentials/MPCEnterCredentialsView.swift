//
//  MPCEnterCodeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

struct MPCEnterCredentialsView: View, UserDataValidator, ViewAnalyticsLogger {
    
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    
    var mode: InputMode = .freeInput
    let analyticsName: Analytics.ViewName
    let credentialsCallback: (MPCActivateCredentials)->()
    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""
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
                }
                actionButtonView()
                Spacer()
            }
        }
        .passViewAnalyticsDetails(logger: self)
        .trackAppearanceAnalytics(analyticsLogger: self)
        .scrollDisabled(true)
        .padding()
        .onAppear(perform: onAppear)
        .displayError($error)
    }
    
}

// MARK: - Private methods
private extension MPCEnterCredentialsView {
    func onAppear() {
        switch mode {
        case .freeInput:
            return
        case .strictEmail(let email):
            self.emailInput = email
        }
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.importMPCWalletTitle.localizedMPCProduct())
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
            Text(String.Constants.importMPCWalletSubtitle.localizedMPCProduct())
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
        }
    }
    
    var emailInputDisabled: Bool {
        switch mode {
        case .freeInput:
            false
        case .strictEmail:
            true
        }
    }
    
    @ViewBuilder
    func emailInputView() -> some View {
        VStack(spacing: 8) {
            UDTextFieldView(text: $emailInput,
                            placeholder: "name@mail.com",
                            hint: String.Constants.emailAssociatedWithWallet.localized(),
                            focusBehaviour: emailInputDisabled ? .default : .activateOnAppear,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            autocorrectionDisabled: true,
                            isErrorState: shouldShowEmailError,
                            focusedStateChangedCallback: { isFocused in
                isEmailFocused = isFocused
            })
            .disabled(emailInputDisabled)
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
        UDTextFieldView(text: $passwordInput,
                        placeholder: String.Constants.password.localized(),
                        focusBehaviour: emailInputDisabled ? .activateOnAppear : .default,
                        autocapitalization: .never,
                        autocorrectionDisabled: true,
                        isSecureInput: true)
    }
    
    var isActionButtonDisabled: Bool {
        !isValidEmailEntered || passwordInput.isEmpty
    }
    
    var isValidEmailEntered: Bool {
        isEmailValid(emailInput)
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
            logButtonPressedAnalyticEvents(button: .continue)
            isLoading = true
            do {
                // Send email action
                let email = emailInput
                try await mpcWalletsService.sendBootstrapCodeTo(email: email)
                let password = passwordInput
                let credentials = MPCActivateCredentials(email: email, password: password)
                credentialsCallback(credentials)
            } catch {
                logAnalytic(event: .sendMPCBootstrapCodeError, parameters: [.error: error.localizedDescription])
                self.error = error
            }
            isLoading = false
        }
    }
}

// MARK: - Open methods
extension MPCEnterCredentialsView {
    enum InputMode {
        case freeInput
        case strictEmail(String)
    }
}

@available(iOS 17.0, *)
#Preview {
    let vc = MPCOnboardingEnterCredentialsViewController()
    let nav = CNavigationController(rootViewController: vc)
    
    return nav
}
