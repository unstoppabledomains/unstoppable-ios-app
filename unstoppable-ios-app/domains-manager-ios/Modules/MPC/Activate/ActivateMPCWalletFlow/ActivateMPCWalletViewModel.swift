//
//  ActivateMPCWalletViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.04.2024.
//

import SwiftUI

@MainActor
final class ActivateMPCWalletViewModel: ObservableObject {
    
    let preFilledEmail: String?
    let activationResultCallback: ActivateMPCWalletFlow.FlowResultCallback
    @Published var navPath: [ActivateMPCWalletFlow.NavigationDestination] = []
    @Published var navigationState: NavigationStateManager?
    @Published var isLoading = false
    @Published var error: Error?
    private var credentials: MPCActivateCredentials?
    
    init(preFilledEmail: String?,
         activationResultCallback: @escaping ActivateMPCWalletFlow.FlowResultCallback) {
        self.preFilledEmail = preFilledEmail
        self.activationResultCallback = activationResultCallback
    }
    
    func handleAction(_ action: ActivateMPCWalletFlow.FlowAction) {
        Task {
            do {
                switch action {
                case .didEnterCredentials(let credentials):
                    self.credentials = credentials
                    navPath.append(.enterCode(email: credentials.email))
                case .didPressForgotPassword:
                    navPath.append(.forgotPassword)
                case .didEnterCode(let code):
                    guard let credentials else { return }
                    
                    navPath.append(.activate(credentials: credentials, code: code))
                case .didActivate(let wallet):
                    navigationState?.dismiss = true
                    activationResultCallback(.activated(wallet))
                case .didRequestToChangeEmail:
                    credentials = nil
                    navPath.removeAll()
                }
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
}

