//
//  MPCEnterCodeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

struct MPCEnterCodeView: View {
    
    let codeVerifiedCallback: (String)->()
    @State private var input: String = ""
    @State private var inputType: InputType = .code
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 32) {
            headerView()
            VStack(alignment: .leading, spacing: 8) {
                inputView()
                inputActionButtonView()
            }
            actionButtonView()
            Spacer()
        }
        .padding()
        .padding(EdgeInsets(top: 70, leading: 0, bottom: 0, trailing: 0))
        .animation(.default, value: UUID())
    }
    
}

// MARK: - Private methods
private extension MPCEnterCodeView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text("Unstoppable Guard")
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
            Text("The recovery phrase you created for Unstoppable Guard is required to access your crypto wallet on this device. In addition, you'll be required to verify a 2FA code to complete setup.")
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func inputView() -> some View {
        UDTextFieldView(text: $input,
                        placeholder: inputPlaceholder,
                        focusBehaviour: .activateOnAppear,
                        autocapitalization: .never,
                        autocorrectionDisabled: true)
    }
    
    var inputPlaceholder: String {
        switch inputType {
        case .code:
            "Enter setup code"
        case .email:
            "Enter email"
        }
    }
    
    @ViewBuilder
    func inputActionButtonView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            toggleInputType()
        } label: {
            HStack {
                Text(inputActionCodeMessage)
                    .foregroundStyle(Color.foregroundSecondary)
                Text(inputActionMessage)
                    .foregroundStyle(Color.foregroundAccent)
            }
            .font(.currentFont(size: 16))
        }
        .buttonStyle(.plain)
    }
    
    var inputActionCodeMessage: String {
        switch inputType {
        case .code:
            "Don't have a code yet?"
        case .email:
            "Already have a code?"
        }
    }
    
    var inputActionMessage: String {
        switch inputType {
        case .code:
            "Send to email"
        case .email:
            "Enter code"
        }
    }
    
    func toggleInputType() {
        input = ""
        switch inputType {
        case .code:
            self.inputType = .email
        case .email:
            self.inputType = .code
        }
    }
    
    @ViewBuilder
    func actionButtonView() -> some View {
        UDButtonView(text: actionButtonTitle, 
                     style: .large(.raisedPrimary),
                     isLoading: isLoading,
                     callback: actionButtonPressed)
        .disabled(input.isEmpty)
    }
    
    var actionButtonTitle: String {
        switch inputType {
        case .code:
            "Submit setup code"
        case .email:
            "Send code"
        }
    }
    
    func actionButtonPressed() {
        switch inputType {
        case .code:
            sendCode()
        case .email:
            sendEmail()
        }
    }
    
    func sendCode() {
        Task {
            isLoading = true
            // Send code
            await Task.sleep(seconds: 1.0)
            isLoading = false
            codeVerifiedCallback(input)
        }
    }
    
    func sendEmail() {
        Task {
            isLoading = true
            // Send email action
            await Task.sleep(seconds: 1.0)
            isLoading = false
            toggleInputType()
        }
    }
}

// MARK: - Private methods
private extension MPCEnterCodeView {
    enum InputType {
        case code, email
    }
}

@available(iOS 17.0, *)
#Preview {
    let view = MPCEnterCodeView(codeVerifiedCallback: { _ in })
    let vc = UIHostingController(rootView: view)
    let nav = CNavigationController(rootViewController: vc)
    
    return nav
}
