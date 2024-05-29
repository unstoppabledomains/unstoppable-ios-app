//
//  PurchaseMPCWalletTakeoverProgressView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverProgressView: View {
    
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    @Environment(\.ecomPurchaseMPCWalletService) private var ecomPurchaseMPCWalletService

    let credentials: MPCTakeoverCredentials
    let finishCallback: EmptyCallback
    @State private var takeoverState: MPCWalletTakeoverState = .readyForTakeover
    @State private var error: Error?

    var body: some View {
        VStack {
            MPCWalletStateCardView(title: cardTitle,
                                   subtitle: cardSubtitle,
                                   mode: .takeover(takeoverState))
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverProgressView {
    var cardTitle: String {
        "Preparing Wallet..."
    }
    
    var cardSubtitle: String {
        "~ 02:36"
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
                try await ecomPurchaseMPCWalletService.runTakeover(credentials: credentials)
                // Send email action
                try await mpcWalletsService.sendBootstrapCodeTo(email: credentials.email)
                finishCallback()
            } catch {
                takeoverState = .failed(.unknown)
            }
        }
    }
}

#Preview {
    PurchaseMPCWalletTakeoverProgressView(credentials: .init(email: "qq@qq.qq", password: ""),
                                          finishCallback: { })
}
