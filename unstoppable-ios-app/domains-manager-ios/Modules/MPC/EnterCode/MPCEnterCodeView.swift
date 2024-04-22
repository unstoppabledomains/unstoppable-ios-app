//
//  MPCEnterPassphraseView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

struct MPCEnterCodeView: View {
        
    @Environment(\.mpcWalletsService) private var mpcWalletsService

    let email: String
    let enterCodeCallback: (String)->()
    @State private var input: String = ""
    @State private var isRefreshingCode = false
    @State private var resendCodeCounter: Int?
    @State private var error: Error?
    private let resendCodeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            VStack(spacing: isIPSE ? 16 : 32) {
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
        .onReceive(resendCodeTimer) { _ in
            if let resendCodeCounter {
                if resendCodeCounter <= 0 {
                    self.resendCodeCounter = nil
                } else {
                    self.resendCodeCounter = resendCodeCounter - 1
                }
            }
        }
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
//                        autocapitalization: .characters,
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
        enterCodeCallback(input)
    }
    
    @ViewBuilder
    func haventReceiveCodeButtonView() -> some View {
        UDButtonView(text: resendCodeTitle,
                     style: .large(.ghostPrimary),
                     isLoading: isRefreshingCode,
                     callback: haventReceivedCodeButtonPressed)
        .disabled(resendCodeCounter != nil)
    }
    
    var resendCodeTitle: String {
        var title = String.Constants.resendCode.localized()
        if let resendCodeCounter {
            let counterValue = resendCodeCounter > 9 ? "\(resendCodeCounter)" : "0\(resendCodeCounter)"
            title += " (0:\(counterValue))"
        }
        return title
    }
    
    func haventReceivedCodeButtonPressed() {
        Task {
            isRefreshingCode = true
            do {
                try await mpcWalletsService.sendBootstrapCodeTo(email: email)
            } catch {
                self.error = error
            }
            resendCodeCounter = 30
            isRefreshingCode = false
        }
    }
}
#Preview {
    MPCEnterCodeView(email: "",
                     enterCodeCallback: { _ in })
}

