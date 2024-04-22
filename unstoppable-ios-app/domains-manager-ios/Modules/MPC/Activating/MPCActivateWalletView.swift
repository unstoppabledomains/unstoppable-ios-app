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
    @State private var isLoading = false
    @State private var error: Error?
    @State private var mpcState: String = ""
    @State private var mpcCreateProgress: CGFloat = 0.0
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .displayError($error)
    }
}

// MARK: - Private methods
private extension MPCActivateWalletView {
    func actionButtonPressed() {
        Task { @MainActor in
            
            isLoading = true
            let password = ""
            do {
                let mpcWalletStepsStream = mpcWalletsService.setupMPCWalletWith(code: code, recoveryPhrase: password)
                
                for try await step in mpcWalletStepsStream {
                    updateForSetupMPCWalletStep(step)
                }
                // TODO: - Show explicitly on the UI when design is ready
            } catch MPCWalletError.incorrectCode {
                self.error = MPCWalletError.incorrectCode
            } catch MPCWalletError.incorrectPassword {
                self.error = MPCWalletError.incorrectPassword
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
