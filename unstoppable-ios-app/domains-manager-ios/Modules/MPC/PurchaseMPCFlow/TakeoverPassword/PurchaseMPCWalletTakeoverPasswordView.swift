//
//  PurchaseMPCWalletTakeoverPasswordView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.08.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverPasswordView: View, UserDataValidator, MPCWalletPasswordValidator, ViewAnalyticsLogger {
    
    @Environment(\.claimMPCWalletService) private var claimMPCWalletService
    
    let analyticsName: Analytics.ViewName
    let email: String // Required to ask to save password into keychain
    let passwordCallback: (String)->()
    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""
    @State private var passwordErrors: [MPCWalletPasswordValidationError] = []
    @State private var confirmPasswordInput: String = ""
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: isIPSE ? 16 : 32) {
                    headerView()
                    VStack(alignment: .leading, spacing: isIPSE ? 8 : 24) {
                        ZStack(alignment: .top) {
                            hiddenEmailView()
                            passwordInputView()
                        }
                        confirmPasswordInputView()
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 58)
            }
            .scrollIndicators(.hidden)
            
            actionButtonContainerView()
                .edgesIgnoringSafeArea(.bottom)
        }
        .onChange(of: passwordInput, perform: { newValue in
            validatePasswordInput()
        })
        .onReceive(KeyboardService.shared.keyboardFramePublisher.receive(on: DispatchQueue.main)) { keyboardFrame in
            keyboardHeight = keyboardFrame.height
        }
        .animation(.default, value: UUID())
        .trackAppearanceAnalytics(analyticsLogger: self)
        .onAppear(perform: onAppear)
    }
    
    @ViewBuilder
    func actionButtonContainerView() -> some View {
        VStack(spacing: 0) {
            Spacer()
            Rectangle()
                .frame(height: 16)
                .foregroundStyle(LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top))
            actionButtonView()
                .padding(.bottom, keyboardHeight + 16)
                .padding(.horizontal, 16)
                .background(Color.black)
        }
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverPasswordView {
    func onAppear() {
        emailInput = email
        validatePasswordInput()
    }
    
    func validatePasswordInput() {
        passwordErrors = validateWalletPassword(passwordInput)
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.createPassword.localized())
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
            Text(String.Constants.mpcTakeoverPasswordSubtitle.localized())
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func hiddenEmailView() -> some View {
        UDTextFieldView(text: $emailInput,
                        placeholder: "",
                        hint: String.Constants.emailAssociatedWithWallet.localized(),
                        focusBehaviour: .default,
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        autocorrectionDisabled: true,
                        isErrorState: false)
        .opacity(0.01)
        .allowsHitTesting(false)
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
        if isPasswordRequirementMet(requirement, passwordErrors: passwordErrors) {
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
    
    var isActionButtonDisabled: Bool {
        !isValidPasswordEntered || passwordInput != confirmPasswordInput
    }
    
    var isValidPasswordEntered: Bool {
        passwordErrors.isEmpty
    }
    
    @ViewBuilder
    func actionButtonView() -> some View {
        continueButton()
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
        let password = passwordInput
        passwordCallback(password)
    }
}

#Preview {
    PurchaseMPCWalletTakeoverPasswordView(analyticsName: .unspecified,
                                          email: "qq@qq.qq",
                                          passwordCallback: { _ in })
}
