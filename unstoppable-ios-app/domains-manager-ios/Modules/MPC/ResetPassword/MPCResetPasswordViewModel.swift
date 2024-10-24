//
//  MPCResetPasswordViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.10.2024.
//

import SwiftUI

@MainActor
final class MPCResetPasswordViewModel: ObservableObject {
    
    let resetPasswordData: MPCResetPasswordData
    let resetResultCallback: MPCResetPasswordFlow.FlowResultCallback
    @Published var navPath: NavigationPathWrapper<MPCResetPasswordFlow.NavigationDestination> = .init()
    @Published var navigationState: NavigationStateManager?
    @Published var isLoading = false
    @Published var error: Error?
    private var newPassword: String?
    
    init(resetPasswordData: MPCResetPasswordData,
         resetResultCallback: @escaping MPCResetPasswordFlow.FlowResultCallback) {
        self.resetPasswordData = resetPasswordData
        self.resetResultCallback = resetResultCallback
    }
    
    func handleAction(_ action: MPCResetPasswordFlow.FlowAction) {
        Task {
            do {
                switch action {
                case .didEnterNewPassword(let newPassword):
                    self.newPassword = newPassword
                    navPath.append(.enterCode(email: resetPasswordData.email))
                case .didEnterCode(let code):
                    guard let newPassword else { return }
                    
                    let data = MPCResetPasswordFlow.ResetPasswordFullData(resetPasswordData: resetPasswordData,
                                                                          newPassword: newPassword,
                                                                          code: code)
                    navPath.append(.activate(data))
                case .didActivate(let wallet):
                    navigationState?.dismiss = true
                    resetResultCallback(.restored(wallet))
                }
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
}

