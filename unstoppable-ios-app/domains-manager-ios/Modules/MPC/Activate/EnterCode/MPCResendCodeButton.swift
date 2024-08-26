//
//  MPCResendCodeButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.04.2024.
//

import SwiftUI

typealias ResendConfirmationCodeBlock = (String) async throws -> ()

struct MPCResendCodeButton: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName

    let email: String
    let resendAction: ResendConfirmationCodeBlock
    @State private var isRefreshingCode = false
    @State private var resendCodeCounter: Int?
    @State private var error: Error?
    private let resendCodeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        UDButtonView(text: resendCodeTitle,
                     style: .large(.ghostPrimary),
                     isLoading: isRefreshingCode,
                     callback: haventReceivedCodeButtonPressed)
        .disabled(resendCodeCounter != nil)
        .animation(.default, value: UUID())
        .displayError($error)
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
private extension MPCResendCodeButton {
    var resendCodeTitle: String {
        var title = String.Constants.resendCode.localized()
        if let resendCodeCounter {
            let counterValue = resendCodeCounter > 9 ? "\(resendCodeCounter)" : "0\(resendCodeCounter)"
            title += " (0:\(counterValue))"
        }
        return title
    }
    
    func haventReceivedCodeButtonPressed() {
        logButtonPressedAnalyticEvents(button: .resendCode)
        Task {
            isRefreshingCode = true
            do {
                try await resendAction(email)
            } catch {
                self.error = error
            }
            resendCodeCounter = 30
            isRefreshingCode = false
        }
    }
}

#Preview {
    MPCResendCodeButton(email: "",
                        resendAction: { _ in })
}
