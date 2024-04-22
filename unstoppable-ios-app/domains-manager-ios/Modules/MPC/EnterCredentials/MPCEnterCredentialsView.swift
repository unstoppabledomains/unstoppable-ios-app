//
//  MPCEnterCodeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

struct MPCEnterCredentialsView: View, UserDataValidator {
    
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    
    let codeVerifiedCallback: (String)->()
    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 32) {
            headerView()
            VStack(alignment: .leading, spacing: 16) {
                emailInputView()
                passwordInputView()
            }
            actionButtonView()
            Spacer()
        }
        .padding()
        .padding(EdgeInsets(top: 70, leading: 0, bottom: 0, trailing: 0))
        .animation(.default, value: UUID())
        .displayError($error)
    }
    
}

// MARK: - Private methods
private extension MPCEnterCredentialsView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.importMPCWalletTitle.localized())
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
            Text(String.Constants.importMPCWalletSubtitle.localized())
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func emailInputView() -> some View {
        UDTextFieldView(text: $emailInput,
                        placeholder: "name@mail.com",
                        hint: String.Constants.emailAssociatedWithWallet.localized(),
                        focusBehaviour: .activateOnAppear,
                        autocapitalization: .never,
                        autocorrectionDisabled: true)
    }
    
    @ViewBuilder
    func passwordInputView() -> some View {
        UDTextFieldView(text: $passwordInput,
                        placeholder: String.Constants.password.localized(),
                        focusBehaviour: .default,
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
            isLoading = true
            do {
                // Send email action
                try await mpcWalletsService.sendBootstrapCodeTo(email: emailInput)
                let code = passwordInput.trimmedSpaces.uppercased()
                codeVerifiedCallback(code)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    let view = MPCEnterCredentialsView(codeVerifiedCallback: { _ in })
    let vc = UIHostingController(rootView: view)
    let nav = CNavigationController(rootViewController: vc)
    
    return nav
}
