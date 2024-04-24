//
//  ActivateMPCWalletViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.04.2024.
//

import SwiftUI

@MainActor
final class ActivateMPCWalletViewModel: ObservableObject {
    
    @Published var navPath: [ActivateMPCWalletFlow.NavigationDestination] = []
    @Published var navigationState: NavigationStateManager?
    @Published var isLoading = false
    @Published var error: Error?
    private var credentials: MPCActivateCredentials?
    
    func handleAction(_ action: ActivateMPCWalletFlow.FlowAction) {
        Task {
            do {
                switch action {
                case .didEnterCredentials(let credentials):
                    self.credentials = credentials
                    navPath.append(.enterCode(email: credentials.email))
                case .didEnterCode(let code):
                    guard let credentials else { return }
                    
                    navPath.append(.activate(credentials: credentials, code: code))
                case .didActivate:
                    navigationState?.dismiss = true
                case .didRequestToChangeEmail:
                    self.credentials = nil
                    navPath.removeAll()
                }
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
}

