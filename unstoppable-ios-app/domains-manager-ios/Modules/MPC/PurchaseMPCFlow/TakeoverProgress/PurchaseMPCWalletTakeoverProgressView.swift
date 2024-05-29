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
        ZStack {
            MPCWalletStateCardView(title: cardTitle,
                                   subtitle: cardSubtitle,
                                   mode: .takeover(takeoverState))
            
            VStack {
                Spacer()
                actionButton()
            }
            .padding()
        }
        .animation(.default, value: UUID())
        .onAppear(perform: onAppear)
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
                try await ecomPurchaseMPCWalletService.runTakeover(credentials: credentials)
                // Send email action
                try await mpcWalletsService.sendBootstrapCodeTo(email: credentials.email)
                finishCallback()
            } catch {
                takeoverState = .failed(.unknown)
            }
        }
    }
    
    @ViewBuilder
    func actionButton() -> some View {
        switch takeoverState {
        case .readyForTakeover, .inProgress:
            EmptyView()
        case .failed:
            UDButtonView(text: String.Constants.tryAgain.localized(),
                         style: .large(.raisedPrimary),
                         callback: actionButtonPressed)
        }
    }
    
    func actionButtonPressed() {
        runTakeover()
    }
}

#Preview {
    PurchaseMPCWalletTakeoverProgressView(credentials: .init(email: "qq@qq.qq", password: ""),
                                          finishCallback: { })
}
