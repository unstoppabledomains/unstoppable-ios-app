//
//  PurchaseMPCWalletViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

@MainActor
final class PurchaseMPCWalletViewModel: ObservableObject, ViewErrorHolder {
    
    @Published var navPath: [PurchaseMPCWallet.NavigationDestination] = []
    @Published var navigationState: NavigationStateManager?
    @Published var isLoading = false
    @Published var error: Error?
    
    func handleAction(_ action: PurchaseMPCWallet.FlowAction) {
        Task {
            switch action {
                // Common path
            case .authWithProvider(let provider):
                await self.authWithProvider(provider)
                navPath.append(.scanWalletAddress)
            }
        }
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletViewModel {
    func authWithProvider(_ provider: LoginProvider) async {
        UDVibration.buttonTap.vibrate()
        switch provider {
        case .email:
            moveToEnterEmailScreen()
        case .google:
            await loginWithGoogle()
        case .twitter:
            await loginWithTwitter()
        case .apple:
            loginWithApple()
        }
    }
    
    func moveToEnterEmailScreen() {
        
    }
    
    func loginWithEmail(_ email: String, password: String) async {
        await runAuthOperation {
            try await appContext.ecomPurchaseMPCWalletService.authoriseWithEmail(email, password: password)
        }
    }
    
    func loginWithGoogle() async {
        await runAuthOperation {
            try await appContext.ecomPurchaseMPCWalletService.authoriseWithGoogle()
        }
    }
    
    func loginWithTwitter() async {
        await runAuthOperation {
            try await appContext.ecomPurchaseMPCWalletService.authoriseWithTwitter()
        }
    }
    
    func loginWithApple() { }
    
    func runAuthOperation(_ block: @escaping (() async throws -> ())) async {
        isLoading = true
        await performAsyncErrorCatchingBlock(block)
        isLoading = false
        // Move to next view
    }
}

