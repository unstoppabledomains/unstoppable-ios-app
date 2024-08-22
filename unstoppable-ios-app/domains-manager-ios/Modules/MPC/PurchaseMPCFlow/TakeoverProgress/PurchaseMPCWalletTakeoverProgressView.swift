//
//  PurchaseMPCWalletTakeoverProgressView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverProgressView: View, ViewAnalyticsLogger {
    
    @Environment(\.claimMPCWalletService) private var claimMPCWalletService

    let analyticsName: Analytics.ViewName
    @State var credentials: MPCTakeoverCredentials
    let finishCallback: EmptyCallback
    @State private var takeoverState: MPCWalletTakeoverState = .readyForTakeover
    @State private var error: Error?
    @State private var didFinishTakeover = false
    @State private var numberOfFailedAttempts = 0
    @State private var enterDataType: MPCActivateWalletEnterDataType?

    var body: some View {
        ZStack {
            MPCWalletStateCardView(title: cardTitle,
                                   subtitle: cardSubtitle,
                                   mode: .takeover(takeoverState))
            
            VStack {
                Spacer()
                actionButtons()
            }
            .padding()
        }
        .animation(.default, value: UUID())
        .trackAppearanceAnalytics(analyticsLogger: self)
        .onAppear(perform: onAppear)
        .sheet(item: $enterDataType) { dataType in
            MPCActivateWalletEnterView(dataType: dataType,
                                       email: credentials.email,
                                       confirmationCallback: { value in
                switch dataType {
                case .passcode:
                    self.credentials.code = value
                case .password:
                    return
                }
                runTakeover()
            }, changeEmailCallback: nil)
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverProgressView {
    var cardTitle: String {
        switch takeoverState {
        case .readyForTakeover, .inProgress:
            String.Constants.mpcTakeoverInProgressTitle.localized()
        case .failed:
            String.Constants.somethingWentWrong.localized()
        }
    }
    
    var cardSubtitle: String {
        switch takeoverState {
        case .readyForTakeover, .inProgress:
            String.Constants.mpcTakeoverInProgressSubtitle.localized()
        case .failed:
            String.Constants.mpcProductName.localized()
        }
    }
    
    func onAppear() {
        runTakeoverIfNeeded()
    }
    
    func runTakeoverIfNeeded() {
        if case .readyForTakeover = takeoverState {
            runTakeover()
        }
    }
    
    func runTakeover() {
        Task {
            takeoverState = .inProgress
            do {
                if !didFinishTakeover {
                    logAnalytic(event: .mpcTakeoverStarted)
                    try await claimMPCWalletService.runTakeover(credentials: credentials)
                    logAnalytic(event: .mpcTakeoverFinished)
                }
                didFinishTakeover = true
                finishCallback()
            } catch MPCWalletError.incorrectCode {
                logAnalytic(event: .didFailActivateMPCWalletPasscode)
                didFailWithError(.incorrectPasscode)
            } catch {
                takeoverState = .failed(.unknown)
                numberOfFailedAttempts += 1
                if didFinishTakeover {
                    logAnalytic(event: .sendMPCBootstrapCodeError, 
                                parameters: [.error: error.localizedDescription,
                                             .numberOfAttempts: String(numberOfFailedAttempts)])
                } else {
                    logAnalytic(event: .mpcTakeoverFailed, 
                                parameters: [.error: error.localizedDescription,
                                             .numberOfAttempts: String(numberOfFailedAttempts)])
                }
            }
        }
    }
    
    func didFailWithError(_ error: MPCWalletTakeoverError) {
        takeoverState = .failed(error)
        switch error {
        case .incorrectPasscode:
            enterDataType = .passcode(resendCode)
        case .unknown:
            return
        }
    }
    
    func resendCode(email: String) async throws {
        try await claimMPCWalletService.sendVerificationCodeTo(email: email)
    }
    
    @ViewBuilder
    func actionButtons() -> some View {
        switch takeoverState {
        case .readyForTakeover, .inProgress:
            EmptyView()
        case .failed:
            VStack(spacing: 16) {
                contactSupportButton()
                tryAgainButton()
            }
        }
    }
    
    @ViewBuilder
    func contactSupportButton() -> some View {
        if numberOfFailedAttempts >= 2 {
            UDButtonView(text: String.Constants.contactSupport.localized(),
                         style: .large(.ghostPrimary),
                         callback: contactSupportButtonPressed)
        }
    }
    
    func contactSupportButtonPressed() {
        logButtonPressedAnalyticEvents(button: .contactSupport)
        let recipientMailAddress = Constants.UnstoppableSupportMail
        let subject = String.Constants.feedbackEmailSubject.localized(UserDefaults.buildVersion)
        openEmailFormWith(recipientMailAddress: recipientMailAddress,
                          subject: subject)
    }
    
    @ViewBuilder
    func tryAgainButton() -> some View {
        UDButtonView(text: String.Constants.tryAgain.localized(),
                     style: .large(.raisedPrimary),
                     callback: tryAgainButtonPressed)
    }
    
    func tryAgainButtonPressed() {
        logButtonPressedAnalyticEvents(button: .tryAgain)
        runTakeover()
    }
}

#Preview {
    PurchaseMPCWalletTakeoverProgressView(analyticsName: .unspecified,
                                          credentials: .init(email: "qq@qq.qq", password: ""),
                                          finishCallback: { })
}
