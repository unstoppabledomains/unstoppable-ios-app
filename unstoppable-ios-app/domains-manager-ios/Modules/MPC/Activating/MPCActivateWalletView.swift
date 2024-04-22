//
//  MPCActivateWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.04.2024.
//

import SwiftUI

struct MPCActivateWalletView: View {

    @Environment(\.mpcWalletsService) private var mpcWalletsService

    @State var credentials: MPCActivateCredentials
    @State var code: String
    let mpcWalletCreatedCallback: (UDWallet)->()
    
    @State private var activationState: ActivationState = .readyToActivate
    @State private var isLoading = false
    @State private var mpcStateTitle: String = ""
    @State private var mpcCreateProgress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                headerView()
                Spacer()
            }
            .padding()
            .padding(EdgeInsets(top: 70, leading: 0, bottom: 0, trailing: 0))
            
            mpcStateView()
                .padding(.top, 70)
            
            VStack {
                Spacer()
                actionButtonView()
                    .padding(.horizontal)
                    .padding(.bottom, safeAreaInset.bottom)
            }
        }
        .ignoresSafeArea()
        .animation(.default, value: UUID())
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension MPCActivateWalletView {
    func onAppear() {
        activateWalletIfReady()
    }
    
    func activateWalletIfReady() {
        if case .readyToActivate = activationState {
            activateMPCWallet()
        }
    }
    
    func activateMPCWallet() {
        activationState = .activating
        mpcCreateProgress = 0
        Task { @MainActor in
            
            isLoading = true
            let password = credentials.password
            do {
                let mpcWalletStepsStream = mpcWalletsService.setupMPCWalletWith(code: code, recoveryPhrase: password)
                
                for try await step in mpcWalletStepsStream {
                    updateForSetupMPCWalletStep(step)
                }
                
            } catch MPCWalletError.incorrectCode {
                didFailWithError(.incorrectPasscode)
            } catch MPCWalletError.incorrectPassword {
                didFailWithError(.incorrectPassword)
            } catch {
                didFailWithError(.unknown)
            }
            isLoading = false
        }
    }
    
    func didFailWithError(_ error: ActivationError) {
        mpcStateTitle = error.title
        activationState = .failed(error)
    }
    
    @MainActor
    func updateForSetupMPCWalletStep(_ step: SetupMPCWalletStep) {
        mpcStateTitle = step.title
        mpcCreateProgress = CGFloat(step.stepOrder) / CGFloat (SetupMPCWalletStep.numberOfSteps)
        switch step {
        case .finished(let mpcWallet):
            activationState = .activated(mpcWallet)
        case .failed(let url):
            if let url {
                shareItems([url], completion: nil)
            }
        default:
            return
        }
    }
}

private extension MPCActivateWalletView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.enterMPCWalletVerificationCodeTitle.localized())
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
        }
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    func mpcStateView() -> some View {
        ZStack {
            Image.confirmSendTokenGrid
                .resizable()
            VStack(alignment: .leading) {
                stateProgressView()
                    .squareFrame(56)
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mpcStateTitle)
                            .font(.currentFont(size: 28, weight: .bold))
                            .foregroundStyle(Color.foregroundDefault)
                        Text("MPC Wallet")
                            .font(.currentFont(size: 16))
                            .foregroundStyle(Color.foregroundDefault)
                    }
                    Spacer()
                }
            }
            .padding(16)
        }
        .foregroundStyle(Color.foregroundDefault)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(stateBackgroundView())
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.backgroundDefault, lineWidth: 4)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(stateBorderColor(), lineWidth: 1)
            }
        )
        .padding(32)
    }
    
    @ViewBuilder
    func stateProgressView() -> some View {
        switch activationState {
        case .readyToActivate, .activating:
            CircularProgressView(progress: mpcCreateProgress)
        case .activated:
            Image.checkCircle
                .resizable()
                .foregroundStyle(stateBorderColor())
        case .failed:
            Image.crossWhite
                .resizable()
                .foregroundStyle(stateBorderColor())
        }
    }
    
    @ViewBuilder
    func stateBackgroundView() -> some View {
        switch activationState {
        case .readyToActivate, .activating, .failed:
            Color.backgroundOverlay
        case .activated:
            Color.backgroundSuccessEmphasis
        }
    }
    
    func stateBorderColor() -> Color {
        switch activationState {
        case .readyToActivate, .activating:
            .foregroundAccent
        case .activated:
            .backgroundSuccessEmphasis
        case .failed:
            .backgroundDangerEmphasis
        }
    }
    
    @ViewBuilder
    func actionButtonView() -> some View {
        switch activationState {
        case .readyToActivate, .activating:
            EmptyView()
        case .activated, .failed:
            UDButtonView(text: actionButtonTitle,
                         style: .large(.raisedPrimary),
                         callback: actionButtonPressed)
        }
    }
    
    var actionButtonTitle: String {
        switch activationState {
        case .activated:
            String.Constants.getStarted.localized()
        case .readyToActivate, .activating:
            ""
        case .failed(let error):
            error.actionTitle
        }
    }
    
    func actionButtonPressed() {
        switch activationState {
        case .activated(let mpcWallet):
            mpcWalletCreatedCallback(mpcWallet)
        case .readyToActivate, .activating:
            Debugger.printFailure("Inconsistent state. Button should not be visible", critical: true)
        case .failed(let error):
            handleActionFor(error: error)
        }
    }
    
    func handleActionFor(error: ActivationError) {
        switch error {
        case .incorrectPasscode:
            return
        case .incorrectPassword:
            return
        case .unknown:
            activateMPCWallet()
        }
    }
}

// MARK: - Private methods
private extension MPCActivateWalletView {
    enum ActivationState {
        case readyToActivate
        case activating
        case failed(ActivationError)
        case activated(UDWallet)
    }
    
    enum ActivationError {
        case incorrectPassword
        case incorrectPasscode
        case unknown
        
        var title: String {
            switch self {
            case .incorrectPasscode:
                "Wrong passcode"
            case .incorrectPassword:
                "Wrong password"
            case .unknown:
                "Something went wrong"
            }
        }
        
        var actionTitle: String {
            switch self {
            case .incorrectPasscode:
                "Re-enter passcode"
            case .incorrectPassword:
                "Re-enter password"
            case .unknown:
                "Retry"
            }
        }
    }
}

#Preview {
    MPCActivateWalletView(credentials: .init(email: "",
                                             password: ""),
                          code: "",
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
                .foregroundStyle(Color.backgroundMuted)
            
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
