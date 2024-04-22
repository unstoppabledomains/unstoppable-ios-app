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
    @State private var error: Error?
    @State private var mpcState: String = ""
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
                    .padding()
            }
        }
        .ignoresSafeArea()
        .animation(.default, value: UUID())
        .displayError($error)
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
                self.error = MPCWalletError.incorrectCode
                activationState = .failed
            } catch MPCWalletError.incorrectPassword {
                self.error = MPCWalletError.incorrectPassword
                activationState = .failed
            } catch {
                self.error = error
                activationState = .failed
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
                        Text(mpcState)
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
//        .shadow(color: stateBorderColor(),
//                radius: 1,
//                x: 0,
//                y: 0)
//        .overlay {
//            RoundedRectangle(cornerRadius: 12)
//                .stroke(Color.backgroundDefault, lineWidth: 1)
//        }
//        .overlay {
//            RoundedRectangle(cornerRadius: 12)
//                .stroke(Color.backgroundDefault, lineWidth: 1)
//        }
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
            UDButtonView(text: String.Constants.getStarted.localized(),
                         style: .large(.raisedPrimary),
                         callback: actionButtonPressed)
        }
    }
    
    func actionButtonPressed() {
        
    }
}

// MARK: - Private methods
private extension MPCActivateWalletView {
    enum ActivationState {
        case readyToActivate
        case activating
        case failed
        case activated
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
