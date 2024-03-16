//
//  MPCEnterPassphraseView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

struct MPCEnterPassphraseView: View {
    
    let code: String
    let mpcWalletCreatedCallback: (UDMPCWallet)->()
    @State private var input: String = ""
    @State private var isLoading = false
    @State private var error: Error?
    @State private var mpcState: String = ""

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                headerView()
                inputView()
                actionButtonView()
                Spacer()
            }
            .padding()
            .padding(EdgeInsets(top: 70, leading: 0, bottom: 0, trailing: 0))
            if isLoading {
                Color.black.opacity(0.3)
                mpcStateView()
            }
        }
        .ignoresSafeArea()
        .animation(.default, value: UUID())
        .displayError($error)
    }
}


// MARK: - Private methods
private extension MPCEnterPassphraseView {
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
                        placeholder: "Password",
                        focusBehaviour: .activateOnAppear,
                        autocapitalization: .never,
                        autocorrectionDisabled: true,
                        isSecureInput: true)
    }
    
    @ViewBuilder
    func actionButtonView() -> some View {
        UDButtonView(text: "Access wallet",
                     style: .large(.raisedPrimary),
                     isLoading: isLoading,
                     callback: actionButtonPressed)
        .disabled(input.isEmpty)
    }
    
    func actionButtonPressed() {
        Task {
            await KeyboardService.shared.hideKeyboard()
            
            isLoading = true
            do {
                let mpcWalletStepsStream = MPCNetworkService.shared.signForNewDeviceWith(code: code, recoveryPhrase: input)
                
                for try await step in mpcWalletStepsStream {
                    updateForSetupMPCWalletStep(step)
                }
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func updateForSetupMPCWalletStep(_ step: SetupMPCWalletStep) {
        mpcState = step.title
        switch step {
        case .finished(let mpcWallet):
            mpcWalletCreatedCallback(mpcWallet)
        default:
            return
        }
    }
    
    @ViewBuilder
    func mpcStateView() -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color.foregroundDefault)
            Text(mpcState)
                .bold()
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.foregroundDefault)
        .frame(width: 300, height: 150)
        .background(Color.backgroundDefault)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}
#Preview {
    MPCEnterPassphraseView(code: "",
                           mpcWalletCreatedCallback: { _ in })
}
