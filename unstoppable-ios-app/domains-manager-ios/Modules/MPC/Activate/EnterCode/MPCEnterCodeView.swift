//
//  MPCEnterPassphraseView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

struct MPCEnterCodeView: View, ViewAnalyticsLogger {
        
    let analyticsName: Analytics.ViewName
    let email: String
    let resendAction: ResendConfirmationCodeBlock
    let enterCodeCallback: (String)->()
    @State private var input: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: isIPSE ? 16 : 32) {
                headerView()
                inputView()
                actionButtonsView()
                Spacer()
            }
            .padding()
        }
        .passViewAnalyticsDetails(logger: self)
        .trackAppearanceAnalytics(analyticsLogger: self)
        .scrollDisabled(true)
        .animation(.default, value: UUID())
    }
}


// MARK: - Private methods
private extension MPCEnterCodeView {   
    @MainActor
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.enterMPCWalletVerificationCodeTitle.localized())
                .font(.currentFont(size: isIPSE ? 26 : 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
            Text(String.Constants.enterMPCWalletVerificationCodeSubtitle.localized(email))
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
        }
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    func inputView() -> some View {
        UDTextFieldView(text: $input,
                        placeholder: "",
                        hint: String.Constants.verificationCode.localized(),
                        rightViewType: .paste,
                        rightViewMode: .always,
                        focusBehaviour: .activateOnAppear,
                        keyboardType: .alphabet,
                        autocapitalization: .characters,
                        textContentType: .oneTimeCode,
                        autocorrectionDisabled: true)
    }
    
    @ViewBuilder
    func actionButtonsView() -> some View {
        VStack(spacing: 16) {
            haventReceiveCodeButtonView()
            confirmButtonView()
        }
    }
    
    @ViewBuilder
    func confirmButtonView() -> some View {
        UDButtonView(text: String.Constants.confirm.localized(),
                     style: .large(.raisedPrimary),
                     callback: actionButtonPressed)
        .disabled(input.isEmpty)
    }
    
    func actionButtonPressed() {
        logButtonPressedAnalyticEvents(button: .confirm)
        enterCodeCallback(input.trimmedSpaces)
    }
    
    @ViewBuilder
    func haventReceiveCodeButtonView() -> some View {
        MPCResendCodeButton(email: email,
                            resendAction: resendAction)
    }
}

#Preview {
    NavigationStack {
        MPCEnterCodeView(analyticsName: .mpcEnterCodeOnboarding,
                         email: "", 
                         resendAction: { _ in },
                         enterCodeCallback: { _ in })
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Back")
            }
        }
    }
}

