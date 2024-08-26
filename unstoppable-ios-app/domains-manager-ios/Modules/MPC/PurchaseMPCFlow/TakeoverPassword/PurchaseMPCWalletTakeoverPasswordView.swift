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
    let passwordCallback: (String)->()
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
                        passwordInputView()
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
        validatePasswordInput()
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
            Text(String.Constants.mpcTakeoverCredentialsSubtitle.localizedMPCProduct())
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
        }
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
                                          passwordCallback: { _ in })
}
