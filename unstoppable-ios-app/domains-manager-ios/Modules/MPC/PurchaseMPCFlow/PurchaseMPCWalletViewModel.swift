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
    case createdMPC(UDWallet)
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
            case .createMPCWallet:
                navPath.append(.enterTakeoverCredentials(purchaseEmail: ""))
            case .didEnterTakeoverCredentials(let credentials):
                self.mpcTakeoverCredentials = MPCTakeoverCredentials(email: credentials.email,
                                                                     password: credentials.password,
                                                                     sendRecoveryLink: true)
                navPath.append(.enterTakeoverCode(email: credentials.email))
            case .didEnterTakeover(let code):
                self.mpcTakeoverCredentials?.code = code
                guard let mpcTakeoverCredentials else { return }
                
                navPath.append(.takeover(mpcTakeoverCredentials))
            case .didFinishTakeover:
                guard let mpcTakeoverCredentials else { return }

                navPath.append(.enterActivationCode(email: mpcTakeoverCredentials.email))
            case .didEnterActivation(let code):
                self.mpcTakeoverCredentials?.code = code
                guard let mpcTakeoverCredentials else { return }

                navPath.append(.activate(credentials: mpcTakeoverCredentials))
            case .didActivate(let wallet):
                finishWith(result: .createdMPC(wallet))
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

