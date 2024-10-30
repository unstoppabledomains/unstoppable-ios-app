//
//  MPCActivateWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.04.2024.
//

import SwiftUI

struct MPCActivateWalletView: View, ViewAnalyticsLogger {

    @Environment(\.mpcWalletsService) private var mpcWalletsService

    let analyticsName: Analytics.ViewName
    @State var flow: SetupMPCFlow
    @State var code: String
    var canGoBack: Bool = true
    let mpcWalletCreatedCallback: (UDWallet)->()
    var changeEmailCallback: EmptyCallback? = nil

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

            mpcStateView()
                .padding(.top, 30)
            
            VStack {
                Spacer()
                actionButtonView()
                    .padding(.horizontal)
                    .padding(.bottom, safeAreaInset.bottom)
            }
        }
        .passViewAnalyticsDetails(logger: self)
        .trackAppearanceAnalytics(analyticsLogger: self)
        .animation(.default, value: UUID())
        .onAppear(perform: onAppear)
        .sheet(item: $enterDataType) { dataType in
            MPCActivateWalletEnterView(dataType: dataType,
                                       email: flow.email,
                                       confirmationCallback: { value in
                switch dataType {
                case .passcode:
                    self.code = value
                case .password:
                    didEnterNewPassword(value)
                }
                activateMPCWallet()
            }, changeEmailCallback: changeEmailCallback)
                .presentationDetents([.medium])
        }
        .navigationBarBackButtonHidden(isBackButtonHidden)
    }
    
    func didEnterNewPassword(_ password: String) {
        switch self.flow {
        case .activate(var credentials):
            credentials.password = password
            self.flow = .activate(credentials)
        case .resetPassword:
            Debugger.printFailure("Incorrect state, new password can't be incorrect", critical: true)
        }
    }
}

// MARK: - Private methods
private extension MPCActivateWalletView {
    var isBackButtonHidden: Bool {
        guard canGoBack else { return true }
        
        switch activationState {
        case .readyToActivate, .activating:
            return true
        case .failed:
            return false
        case .activated:
            return true
        }
    }
    
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
            logAnalytic(event: .willActivateMPCWallet)
            
            isLoading = true
            do {
                let mpcWalletStepsStream: AsyncThrowingStream<SetupMPCWalletStep, Error> = mpcWalletsService.setupMPCWalletWith(code: code,
                                                                                                                                flow: flow)
                
                for try await step in mpcWalletStepsStream {
                    updateForSetupMPCWalletStep(step)
                }
                
            } catch MPCWalletError.incorrectCode {
                logAnalytic(event: .didFailActivateMPCWalletPasscode)
                didFailWithError(.incorrectPasscode)
            } catch MPCWalletError.incorrectPassword {
                logAnalytic(event: .didFailActivateMPCWalletPassword)
                didFailWithError(.incorrectPassword)
            } catch {
                logAnalytic(event: .didFailActivateMPCWalletUnknown)
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
            enterDataType = .passcode(resendCode)
        case .incorrectPassword:
            enterDataType = .password
        case .unknown:
            return
        }
    }
    
    func resendCode(email: String) async throws {
        try await mpcWalletsService.sendBootstrapCodeTo(email: email)
    }
    
    @MainActor
    func updateForSetupMPCWalletStep(_ step: SetupMPCWalletStep) {
        mpcStateTitle = String.Constants.mpcAuthorizing.localized()
        mpcCreateProgress = CGFloat(step.stepOrder) / CGFloat (SetupMPCWalletStep.numberOfSteps)
        switch step {
        case .finished(let mpcWallet):
            logAnalytic(event: .didActivateMPCWallet)
            mpcStateTitle = String.Constants.mpcReadyToUse.localized()
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
    var title: String {
        switch activationState {
        case .readyToActivate, .activating:
            String.Constants.importMPCWalletInProgressTitle.localizedMPCProduct()
        case .failed:
            String.Constants.importMPCWalletFailedTitle.localizedMPCProduct()
        case .activated:
            String.Constants.importMPCWalletFinishedTitle.localizedMPCProduct()
        }
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    func mpcStateView() -> some View {
        MPCWalletStateCardView(title: mpcStateTitle,
                               subtitle: String.Constants.mpcProductName.localized(),
                               mode: .activation(activationState),
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
            logButtonPressedAnalyticEvents(button: .getStarted)
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
            logButtonPressedAnalyticEvents(button: .reEnterPasscode)
            enterDataType = .passcode(resendCode)
        case .incorrectPassword:
            logButtonPressedAnalyticEvents(button: .reEnterPassword)
            enterDataType = .password
        case .unknown:
            logButtonPressedAnalyticEvents(button: .tryAgain)
            activateMPCWallet()
        }
    }
}

#Preview {
    MPCActivateWalletView(analyticsName: .mpcActivationOnboarding,
                          flow: .activate(.init(email: "qq@qq.qq",
                                             password: "")),
                          code: "",
                          mpcWalletCreatedCallback: { _ in },
                          changeEmailCallback: { })
}
