//
//  MPCEnterPassphraseView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import SwiftUI

struct MPCEnterPassphraseView: View {
    
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    
    let code: String
    let mpcWalletCreatedCallback: (UDWallet)->()
    @State private var input: String = ""
    @State private var isLoading = false
    @State private var error: Error?
    @State private var mpcState: String = ""
    @State private var mpcCreateProgress: CGFloat = 0.0

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
        Task { @MainActor in
            KeyboardService.shared.hideKeyboard()
            
            isLoading = true
            do {
                let mpcWalletStepsStream = mpcWalletsService.setupMPCWalletWith(code: code, recoveryPhrase: input)
                
                for try await step in mpcWalletStepsStream {
                    updateForSetupMPCWalletStep(step)
                }
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    @MainActor
    func updateForSetupMPCWalletStep(_ step: SetupMPCWalletStep) {
        mpcState = step.title
        mpcCreateProgress = CGFloat(step.stepOrder) / CGFloat (SetupMPCWalletStep.numberOfSteps)
        switch step {
        case .finished(let mpcWallet):
            mpcWalletCreatedCallback(mpcWallet)
        case .failed(let url):
            if let url {
                shareItems([url], completion: nil)
            }
        default:
            return
        }
    }
    
    @ViewBuilder
    func mpcStateView() -> some View {
        VStack(spacing: 20) {
            CircularProgressView(progress: mpcCreateProgress)
                .squareFrame(60)
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


struct CircularProgressView: View {
    let progress: CGFloat
    var lineWidth: CGFloat = 10
    
    var body: some View {
        ZStack {
            // Background for the progress bar
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.1)
                .foregroundStyle(Color.foregroundAccent)
            
            // Foreground or the actual progress bar
            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.foregroundAccent)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
        }
    }
}
