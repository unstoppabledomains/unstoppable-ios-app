//
//  OnboardingProtectWalletViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import UIKit

@MainActor
protocol ProtectWalletViewPresenterProtocol: BasePresenterProtocol {
    var progress: Double? { get }
    func didSelectProtectionType(_ protectionType: ProtectWalletViewController.ProtectionType)
}

@MainActor
final class OnboardingProtectWalletViewPresenter {
    private weak var onboardingFlowManager: OnboardingFlowManager?
    private let udWalletsService: UDWalletsServiceProtocol
    weak var view: ProtectWalletViewControllerProtocol?
    var progress: Double? { currentProgress }
    
    init(view: ProtectWalletViewControllerProtocol,
         onboardingFlowManager: OnboardingFlowManager,
         udWalletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.onboardingFlowManager = onboardingFlowManager
        self.udWalletsService = udWalletsService
    }
}

// MARK: - ProtectWalletViewPresenterProtocol
extension OnboardingProtectWalletViewPresenter: ProtectWalletViewPresenterProtocol {
    func viewDidLoad() {
        var vaultsPlural: String = String.Constants.wallet.localized().lowercased()
        switch onboardingFlowManager?.onboardingFlow {
        case .existingUser:
            let wallets = udWalletsService.getUserWallets()
            vaultsPlural = String.Constants.pluralWallets.localized(wallets.count)
        case .newUser, .sameUserWithoutWallets:
            vaultsPlural = String.Constants.wallet.localized().lowercased()
        case .none:
            Debugger.printFailure("Onboarding flow manager not assigned", critical: true)
        }
        let title = String.Constants.protectYourWallet.localized(vaultsPlural)
        view?.setTitle(title)
        
        if view?.cNavigationController?.viewControllers.last is WalletConnectedViewController {
            setupDashesProgressView()
        } else {
            Task {
                await MainActor.run {
                    setupDashesProgressView()
                }
            }
        }
    }
 
    func didSelectProtectionType(_ protectionType: ProtectWalletViewController.ProtectionType) {
        UDVibration.buttonTap.vibrate()
        switch protectionType {
        case .biometric:
            self.initiateBiometrics()
        case .passcode:
            self.showSetPasscodeScreen()
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension OnboardingProtectWalletViewPresenter: OnboardingNavigationHandler {
    var viewController: UIViewController? { view }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .protectWallet }
}

// MARK: - OnboardingDataHandling
extension OnboardingProtectWalletViewPresenter: OnboardingDataHandling {
    func willNavigateBack() {
        let wallets = onboardingFlowManager?.onboardingData.wallets ?? []

        wallets.forEach { wallet in
            udWalletsService.remove(wallet: wallet)
        }
        
        onboardingFlowManager?.modifyOnboardingData(modifyingBlock: { $0.wallets = [] })
        Debugger.printWarning("Wallet \(wallets) has been removed")
    }
    
}

// MARK: - Private methods
private extension OnboardingProtectWalletViewPresenter {
    func setupDashesProgressView() {
        view?.setDashesProgress(currentProgress)
    }
    
    var isNewUserRestoreFlow: Bool {
        if case .newUser(let subFlow) = onboardingFlowManager?.onboardingFlow,
           case .restore = subFlow {
            return true
        }
        return false
    }
    
    var currentProgress: Double {
        isNewUserRestoreFlow ? 0.75 : 0.25
    }
    
    var biometricProgress: Double {
        isNewUserRestoreFlow ? 1 : 0.5
    }
    
    func initiateBiometrics() {
        guard let view = self.view else { return }
        
        UIView.animate(withDuration: 0.25) {
            view.setDashesProgress(self.biometricProgress)
        }
        appContext.authentificationService.authenticateWithBiometricWith(uiHandler: view) { [weak self] response in
            guard let self = self else { return }
            
            guard let success = response else {
                self.logAnalytic(event: .biometricAuthFailed)
                DispatchQueue.main.async {
                    self.view?.showSimpleAlert(title: String.Constants.authenticationFailed.localized(), body: String.Constants.biometricsNotAvailable.localized())
                    UIView.animate(withDuration: 0.25) {
                        self.view?.setDashesProgress(self.currentProgress)
                    }
                }
                return
            }
            guard success else {
                self.logAnalytic(event: .biometricAuthFailed)
                Debugger.printInfo(topic: .Security, "Biometrics failed to authenticate")
                DispatchQueue.main.async {
                    self.view?.setDashesProgress(self.currentProgress)
                }
                return
            }
            
            self.logAnalytic(event: .biometricAuthSuccess)
            var settings = User.instance.getSettings()
            settings.touchIdActivated = true
            User.instance.update(settings: settings)
            
            /// Need to give time for blur view disappear. Otherwise it will stuck forever and be visible if user navigate back.
            DispatchQueue.main.asyncAfter(deadline: .now() + appContext.authentificationService.biometricUIProcessingTime) {
                self.didInitiateBiometrics()
            }
        }
    }
    
    func didInitiateBiometrics() {
        onboardingFlowManager?.didSetupProtectWallet()
    }
    
    func showSetPasscodeScreen() {
        onboardingFlowManager?.moveToStep(.createPasscode)
    }
    
    func logAnalytic(event: Analytics.Event) {
        appContext.analyticsService.log(event: event,
                                    withParameters: [.viewName : Analytics.ViewName.onboardingProtectOptions.rawValue])
    }
}
