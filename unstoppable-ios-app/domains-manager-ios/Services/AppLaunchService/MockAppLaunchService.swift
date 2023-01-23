//
//  MockAppLaunchService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import Foundation

final class MockAppLaunchService {
    
    private let coreAppCoordinator: CoreAppCoordinatorProtocol
    private let udWalletsService: UDWalletsServiceProtocol

    init(coreAppCoordinator: CoreAppCoordinatorProtocol,
         udWalletsService: UDWalletsServiceProtocol) {
        self.coreAppCoordinator = coreAppCoordinator
        self.udWalletsService = udWalletsService
    }
    
}

// MARK: - AppLaunchServiceProtocol
extension MockAppLaunchService: AppLaunchServiceProtocol {
    func startWith(sceneDelegate: SceneDelegateProtocol,
                   walletConnectService: WalletConnectServiceProtocol,
                   walletConnectServiceV2: WalletConnectServiceV2Protocol,
                   walletConnectClientService: WalletConnectClientServiceProtocol,
                   completion: @escaping EmptyCallback) {
        #if DEBUG
        Constants.deprecatedTLDs = ["coin"]
        DispatchQueue.main.async {
            switch TestsEnvironment.launchStateToUse {
            case .home:
                self.coreAppCoordinator.showHome(mintingState: .default)
            case .onboardingNew:
                self.clearOnboarding()
                let onboardingFlow = OnboardingNavigationController.OnboardingFlow.newUser(subFlow: nil)
                self.coreAppCoordinator.showOnboarding(onboardingFlow)
            case .onboardingExisting:
                self.clearOnboarding()
                let onboardingFlow = OnboardingNavigationController.OnboardingFlow.existingUser(wallets: self.udWalletsService.getUserWallets())
                self.coreAppCoordinator.showOnboarding(onboardingFlow)
            case .onboardingSameUser:
                self.clearOnboarding()
                let onboardingFlow = OnboardingNavigationController.OnboardingFlow.sameUserWithoutWallets(subFlow: nil)
                self.coreAppCoordinator.showOnboarding(onboardingFlow)
            }
            completion()
        }
        #endif
    }
    
    func addListener(_ listener: AppLaunchServiceListener) {
        
    }
    func removeListener(_ listener: AppLaunchServiceListener) {
        
    }
}

// MARK: - Private methods
private extension MockAppLaunchService {
    func clearOnboarding() {
        UserDefaults.onboardingNavigationInfo = nil
        OnboardingData().persist()
    }
}
