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
                case .authWithProvider(let provider):
                    try await self.authWithProvider(provider)
                case .loginWithEmail(let email, let password):
                    try await self.loginWithEmail(email, password: password)
                    didAuthorise()
                case .confirmPurchase:
                    return
                }
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletViewModel {
    func authWithProvider(_ provider: LoginProvider) async throws {
        UDVibration.buttonTap.vibrate()
        isLoading = true
        defer { isLoading = false }
        
        switch provider {
        case .email:
            moveToEnterEmailScreen()
            return
        case .google:
            try await loginWithGoogle()
        case .twitter:
            try await loginWithTwitter()
        case .apple:
            loginWithApple()
            return
        }
        didAuthorise()
    }
    
    func moveToEnterEmailScreen() {
        navPath.append(.signInWithEmail)
    }
    
    func didAuthorise() {
        navPath.append(.checkout)
    }
    
    func loginWithEmail(_ email: String, password: String) async throws {
        try await appContext.ecomPurchaseMPCWalletService.authoriseWithEmail(email, password: password)
    }
    
    func loginWithGoogle() async throws {
        try await appContext.ecomPurchaseMPCWalletService.authoriseWithGoogle()
    }
    
    func loginWithTwitter() async throws {
        try await appContext.ecomPurchaseMPCWalletService.authoriseWithTwitter()
    }
    
    func loginWithApple() { }
}

