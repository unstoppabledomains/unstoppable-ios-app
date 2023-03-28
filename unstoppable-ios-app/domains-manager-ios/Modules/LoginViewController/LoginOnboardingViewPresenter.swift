//
//  LoginOnboardingViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

final class LoginOnboardingViewPresenter: LoginViewPresenter {
    private weak var onboardingFlowManager: OnboardingFlowManager?

    init(view: LoginViewProtocol,
         onboardingFlowManager: OnboardingFlowManager) {
        super.init(view: view)
        self.onboardingFlowManager = onboardingFlowManager
    }
    
    override func loginWithEmailAction() {
        Task {
//            try? await loginFlowManager?.handle(action: .loginWithEmailAndPassword)
        }
    }
    
    override func userDidAuthorize() {
        Task {
//            do {
//                try await loginFlowManager?.handle(action: .authorized)
//            } catch {
//                authFailedWith(error: error)
//            }
        }
    }
}
