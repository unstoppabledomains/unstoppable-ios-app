//
//  MPCEnterPassphraseView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

struct MPCEnterCodeView: View {
        
    let email: String
    let enterCodeCallback: (String)->()
    @State private var input: String = ""

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                headerView()
                inputView()
                actionButtonsView()
                Spacer()
            }
            .padding()
            .padding(EdgeInsets(top: 70, leading: 0, bottom: 0, trailing: 0))
        }
        .ignoresSafeArea()
        .animation(.default, value: UUID())
    }
}


// MARK: - Private methods
private extension MPCEnterCodeView {    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.enterMPCWalletVerificationCodeTitle.localized())
                .font(.currentFont(size: 32, weight: .bold))
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
                        focusBehaviour: .activateOnAppear,
                        autocapitalization: .characters,
                        autocorrectionDisabled: true)
    }
    
    @ViewBuilder
    func actionButtonsView() -> some View {
        VStack {
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
        enterCodeCallback(input)
    }
    
    @ViewBuilder
    func haventReceiveCodeButtonView() -> some View {
        UDButtonView(text: String.Constants.haventReceivedTheCode.localized(),
                     style: .large(.ghostPrimary),
                     callback: haventReceivedCodeButtonPressed)
    }
    
    func haventReceivedCodeButtonPressed() {
        
    }
}
#Preview {
    MPCEnterCodeView(email: "",
                     enterCodeCallback: { _ in })
}

