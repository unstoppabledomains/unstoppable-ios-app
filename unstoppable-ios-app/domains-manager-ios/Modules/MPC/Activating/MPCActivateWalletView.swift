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
    let changeEmailCallback: ()->()

    @State private var activationState: MPCWalletActivationState = .readyToActivate
    @State private var isLoading = false
    @State private var mpcStateTitle: String = ""
    @State private var mpcCreateProgress: CGFloat = 0.0
    @State private var enterDataType: MPCActivateWalletEnterDataType?
    
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
        .sheet(item: $enterDataType) { dataType in
            MPCActivateWalletEnterView(dataType: dataType,
                                       email: credentials.email,
                                       confirmationCallback: { value in
                switch dataType {
                case .passcode:
                    self.code = value
                case .password:
                    self.credentials.password = value
                }
                activateMPCWallet()
            }, changeEmailCallback: changeEmailCallback)
                .presentationDetents([.medium])
        }
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
    
    func didFailWithError(_ error: MPCWalletActivationError) {
        mpcStateTitle = error.title
        activationState = .failed(error)
        switch error {
        case .incorrectPasscode:
            enterDataType = .passcode
        case .incorrectPassword:
            enterDataType = .password
        case .unknown:
            return
        }
    }
    
    @MainActor
    func updateForSetupMPCWalletStep(_ step: SetupMPCWalletStep) {
        mpcStateTitle = "Authorizing..." // step.title
        mpcCreateProgress = CGFloat(step.stepOrder) / CGFloat (SetupMPCWalletStep.numberOfSteps)
        switch step {
        case .finished(let mpcWallet):
            activationState = .activated(mpcWallet)
        case .failed(let url):
            return
//            if let url {
//                shareItems([url], completion: nil) // For development
//            }
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
        MPCActivateWalletStateCardView(title: mpcStateTitle,
                                       activationState: activationState,
                                       mpcCreateProgress: mpcCreateProgress)
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
    
    func handleActionFor(error: MPCWalletActivationError) {
        switch error {
        case .incorrectPasscode:
            enterDataType = .passcode
        case .incorrectPassword:
            enterDataType = .password
        case .unknown:
            activateMPCWallet()
        }
    }
}

#Preview {
    MPCActivateWalletView(credentials: .init(email: "",
                                             password: ""),
                          code: "",
                          mpcWalletCreatedCallback: { _ in },
                          changeEmailCallback: { })
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