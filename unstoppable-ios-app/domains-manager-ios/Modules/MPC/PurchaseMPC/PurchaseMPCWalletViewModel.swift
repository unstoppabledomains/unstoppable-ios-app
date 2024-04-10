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
    
    func authWithProvider(_ provider: LoginProvider) {
        UDVibration.buttonTap.vibrate()
        switch provider {
        case .email:
            moveToEnterEmailScreen()
        case .google:
            loginWithGoogle()
        case .twitter:
            loginWithTwitter()
        case .apple:
            loginWithApple()
        }
    }
    
    func loginWithEmail(_ email: String, password: String) {
        runAuthOperation {
            try await appContext.ecomPurchaseMPCWalletService.authoriseWithEmail(email, password: password)
        }
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletViewModel {
    func moveToEnterEmailScreen() {
        
    }
    
    func runAuthOperation(_ block: @escaping (() async throws -> ()) ) {
        Task {
            await performAsyncErrorCatchingBlock(block)
            // Move to next view
        }
    }
    
    func loginWithGoogle()  {
        runAuthOperation {
            try await appContext.ecomPurchaseMPCWalletService.authoriseWithGoogle()
        }
    }
    
    func loginWithTwitter() {
        runAuthOperation {
            try await appContext.ecomPurchaseMPCWalletService.authoriseWithTwitter()
        }
    }
    
    func loginWithApple() {
        //        Task {
        //            let request = ASAuthorizationAppleIDProvider().createRequest()
        //            request.requestedScopes = [.email]
        //            let controller = ASAuthorizationController(authorizationRequests: [request])
        //            controller.delegate = self
        //            controller.presentationContextProvider = self
        //            controller.performRequests()
        //        }
    }
}
