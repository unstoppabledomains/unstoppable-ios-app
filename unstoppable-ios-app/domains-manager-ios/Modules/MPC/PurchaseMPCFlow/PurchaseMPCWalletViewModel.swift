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
    @Published var isLoading = false
    @Published var error: Error?
    
    init(createWalletCallback: @escaping AddWalletResultCallback) {
        self.createWalletCallback = createWalletCallback
    }
    
    func handleAction(_ action: PurchaseMPCWallet.FlowAction) {
        switch action {
        case .createNewWallet:
            finishWith(result: .createNew)
        case .buyMPCWallet:
            navPath.append(.udAuth)
        case .didEnterPurchaseCredentials(let credentials):
            purchaseCredentials = credentials
            navPath.append(.checkout(credentials))
        case .didPurchase(let result):
            switch result {
            case .purchased:
                return
            case .alreadyHaveWallet:
                navPath.append(.alreadyHaveWallet(email: purchaseCredentials?.email ?? ""))
            }
        case .didSelectAlreadyHaveWalletAction(let action):
            switch action {
            case .useDifferentEmail:
                navPath.removeLast(2)
            case .importMPC:
                finishWith(result: .importMPC(email: purchaseCredentials?.email ?? ""))
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

