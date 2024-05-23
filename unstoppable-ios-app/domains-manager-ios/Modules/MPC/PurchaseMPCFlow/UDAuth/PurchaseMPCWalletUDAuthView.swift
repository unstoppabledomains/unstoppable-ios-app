//
//  PurchaseMPCWalletUDAuthView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletUDAuthView: View, UserDataValidator {
    
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    
    let credentialsCallback: (MPCPurchaseUDCredentials)->()
    @State private var emailInput: String = ""
    @State private var isLoading = false
    @State private var isEmailFocused = true
    @State private var error: Error?
    
    var body: some View {
        ScrollView {
            VStack(spacing: isIPSE ? 16 : 32) {
                headerView()
                VStack(alignment: .leading, spacing: 16) {
                    emailInputView()
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
private extension PurchaseMPCWalletUDAuthView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.login.localizedMPCProduct())
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
    
    var isActionButtonDisabled: Bool {
        !isValidEmailEntered
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
        let email = emailInput
        let credentials = MPCPurchaseUDCredentials(email: email)
        credentialsCallback(credentials)
    }
}

#Preview {
    PurchaseMPCWalletUDAuthView(credentialsCallback: { _ in })
}