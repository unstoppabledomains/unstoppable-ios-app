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
    
    func handleAction(_ action: ActivateMPCWalletFlow.FlowAction) {
        Task {
            do {
                switch action {
                case .didEnterCredentials(let credentials):
                    return
                case .didEnterCode(let code):
                    return
                case .didActivate:
                    return
                }
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
}

