//
//  PurchaseMPCWalletViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

@MainActor
final class PurchaseMPCWalletViewModel: ObservableObject {
    
    @Published var navPath: [PurchaseMPCWallet.NavigationDestination] = []
    @Published var navigationState: NavigationStateManager?
    private var purchaseCredentials: MPCPurchaseUDCredentials?
    @Published var isLoading = false
    @Published var error: Error?
    
    func handleAction(_ action: PurchaseMPCWallet.FlowAction) {
        switch action {
        case .createNewWallet:
            return
        case .buyMPCWallet:
            navPath.append(.udAuth)
        case .didEnterPurchaseCredentials(let credentials):
            purchaseCredentials = credentials
            navPath.append(.checkout(credentials))
        case .didPurchase:
            return
        }
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletViewModel {

}

