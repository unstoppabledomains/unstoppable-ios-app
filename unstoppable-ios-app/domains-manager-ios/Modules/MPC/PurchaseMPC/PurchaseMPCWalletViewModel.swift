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
    @Published var isLoading = false
    @Published var error: Error?
    
    func handleAction(_ action: PurchaseMPCWallet.FlowAction) {
        Task {
            do {
                switch action {
                    // Common path
                case .scanQRSelected:
                    navPath.append(.scanWalletAddress)
                }
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
}
