//
//  EnterDomainEmailView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.05.2024.
//

import SwiftUI

typealias EnterEmailValueCallback = (String)->()

struct EnterDomainEmailView: View, UserDataValidator {
    
    @Environment(\.dismiss) var dismiss
    
    @State var email: String
    var enteredEmailValueCallback: EnterEmailValueCallback

    var body: some View {
        VStack(spacing: 32) {
            headerView()
            textFieldView()
            Spacer()
            confirmButton()
        }
        .padding()
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 24) {
            Image.mailIcon24
                .resizable()
                .squareFrame(48)
                .foregroundStyle(Color.foregroundSecondary)
            Text(String.Constants.email.localized())
                .titleText()
        }
    }
    
    @ViewBuilder
    func textFieldView() -> some View {
        VStack(spacing: 8) {
            UDTextFieldView(text: $email,
                            placeholder: String.Constants.addYourEmailAddress.localized(),
                            focusBehaviour: .activateOnAppear,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            autocorrectionDisabled: true,
                            isErrorState: !isValidEmailEntered)
            if !isValidEmailEntered {
                incorrectEmailIndicatorView()
            }
        }
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
    
    var isValidEmailEntered: Bool {
        if email.trimmedSpaces.isEmpty {
            return true
        }
        let emailValidationResult = getEmailValidationResult(email)
        switch emailValidationResult {
        case .success:
            if email.contains("@ud.me") {
                return false
            }
            return true
        case .failure:
            return false
        }
    }
    
    @ViewBuilder
    func confirmButton() -> some View {
        UDButtonView(text: String.Constants.confirm.localized(),
                     style: .large(.raisedPrimary),
                     callback: actionButtonPressed)
        .disabled(isActionButtonDisabled)
        .padding(.bottom, 16)
    }
    
    var isActionButtonDisabled: Bool {
        if !email.isEmpty {
            return false
        }
        
        return !isValidEmailEntered
    }
    
    
    func actionButtonPressed() {
        dismiss()
        enteredEmailValueCallback(email)
    }
//    override func isContinueButtonEnabled() -> Bool {
//        if !email.isEmpty,
//           value?.isEmpty == true {
//            return true
//        }
//        return super.isContinueButtonEnabled()
//    }
//    
//    override func valueValidationError() -> String? {
//        guard let email = self.value else { return nil }
//        
//        if email.trimmedSpaces.isEmpty {
//            return nil
//        }
//        
//        let errorMessage = String.Constants.enterValidEmailAddress.localized()
//        let emailValidationResult = getEmailValidationResult(email)
//        
//        switch emailValidationResult {
//        case .success:
//            if email.contains("@ud.me") {
//                return errorMessage
//            }
//            return nil
//        case .failure:
//            return errorMessage
//        }
//    }
}

#Preview {
    EnterDomainEmailView(email: "",
                         enteredEmailValueCallback: { _ in })
}
