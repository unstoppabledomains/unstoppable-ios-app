//
//  PurchaseMPCWalletViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

typealias AddWalletResultCallback = (AddWalletResult)->()

enum AddWalletResult {
    case createNew
    case importMPC(email: String)
}

@MainActor
final class PurchaseMPCWalletViewModel: ObservableObject {
    
    let createWalletCallback: AddWalletResultCallback
    
    @Published var navPath: [PurchaseMPCWallet.NavigationDestination] = []
    @Published var navigationState: NavigationStateManager?
    private var purchaseCredentials: MPCPurchaseUDCredentials?
    private var mpcTakeoverCredentials: MPCTakeoverCredentials?
    @Published var isLoading = false
    @Published var error: Error?
    
    init(createWalletCallback: @escaping AddWalletResultCallback) {
        self.createWalletCallback = createWalletCallback
    }
    
    func handleAction(_ action: PurchaseMPCWallet.FlowAction) {
        Task { @MainActor in
            switch action {
            case .createNewWallet:
                finishWith(result: .createNew)
            case .buyMPCWallet:
                navPath.append(.udAuth)
            case .didEnterPurchaseCredentials(let credentials):
                purchaseCredentials = credentials
                Task {
                    try? await appContext.ecomPurchaseMPCWalletService.guestAuthWith(credentials: credentials)
                }
                navPath.append(.checkout(credentials))
            case .didPurchase(let result):
                let purchaseEmail = purchaseCredentials?.email ?? ""
                switch result {
                case .purchased:
                    navPath.append(.enterTakoverCredentials(purchaseEmail: purchaseEmail))
                case .alreadyHaveWallet:
                    navPath.append(.alreadyHaveWallet(email: purchaseEmail))
                }
            case .didSelectAlreadyHaveWalletAction(let action):
                switch action {
                case .useDifferentEmail:
                    navPath.removeLast(2)
                case .importMPC:
                    finishWith(result: .importMPC(email: purchaseCredentials?.email ?? ""))
                }
            case .didEnterTakeoverCredentials(let credentials):
                self.mpcTakeoverCredentials = MPCTakeoverCredentials(email: credentials.email,
                                                                     password: credentials.password)
                navPath.append(.enterTakoverRecovery(email: credentials.email))
            case .didSelectTakeoverRecoveryTo(let sendRecoveryLink):
                mpcTakeoverCredentials?.sendRecoveryLink = sendRecoveryLink
                guard let mpcTakeoverCredentials else {
                    Debugger.printFailure("Failed to locate takeover credentils", critical: true)
                    return
                }
                navPath.append(.takeover(mpcTakeoverCredentials))
            case .didFinishTakeover:
                finishWith(result: .importMPC(email: mpcTakeoverCredentials?.email ?? ""))
            }
        }
    }
    
    private func finishWith(result: AddWalletResult) {
        navigationState?.dismiss = true
        Task {
            await Task.sleep(seconds: 0.6)
            createWalletCallback(result)
        }
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletViewModel {

}

