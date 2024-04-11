//
//  PurchaseMPCWalletAuthEmailView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.04.2024.
//

import SwiftUI

struct PurchaseMPCWalletAuthEmailView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            titleView()
            inputFieldsView()
            actionButton()
            Spacer()
        }
        .padding()
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletAuthEmailView {
    @ViewBuilder
    func titleView() -> some View {
        VStack(spacing: 16) {
            Text("Enter credentials")
                .titleText()
//            Text("Very meaningful subtitle")
//                .subtitleText()
        }
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    func inputFieldsView() -> some View {
        VStack(spacing: 12) {
            UDTextFieldView(text: $email,
                            placeholder: String.Constants.email.localized())
            UDTextFieldView(text: $password,
                            placeholder: String.Constants.password.localized(),
                            isSecureInput: true)
        }
    }
    
    var didEnterCredentials: Bool {
        !email.trimmedSpaces.isEmpty && !password.trimmedSpaces.isEmpty
    }
    
    @ViewBuilder
    func actionButton() -> some View {
        UDButtonView(text: String.Constants.login.localized(),
                     style: .large(.raisedPrimary)) {
            viewModel.handleAction(.loginWithEmail(email: email, password: password))
        }
                     .disabled(!didEnterCredentials)
    }
}

#Preview {
    PurchaseMPCWalletAuthEmailView()
}
