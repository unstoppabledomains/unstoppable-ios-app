//
//  File.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.04.2022.
//

import UIKit

typealias OnboardingStepHandler = OnboardingNavigationHandler & OnboardingDataHandling

struct WeakOnboardingStepHandler {
    weak var stepHandler: OnboardingStepHandler?
}

final class OnboardingNavigationController: CNavigationController {
    
    var onboardingFlow: OnboardingFlow { flow }
    var onboardingData: OnboardingData = OnboardingData()
    
    private let udWalletsService: UDWalletsServiceProtocol = appContext.udWalletsService
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol = appContext.walletConnectServiceV2
    private var stepHandlers: [WeakOnboardingStepHandler] = []
    private var flow: OnboardingFlow = .newUser(subFlow: nil)

    static func instantiate(flow: OnboardingFlow) -> OnboardingNavigationController {
        let vc = OnboardingNavigationController()
        vc.flow = flow
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        setup()
    }
  
    override func popViewController(animated: Bool, completion: (()->())? = nil) -> UIViewController? {
        if topViewController is ProtectWalletViewController {
            // We don't need to handle additionally back navigation from ProtectVC for existing user flow
            if case .newUser = flow {
                return popTo(RestoreWalletViewController.self)
            }
        } else if topViewController is BackupWalletViewController {
            switch flow {
            case .newUser:
                return popTo(ProtectWalletViewController.self)
            case .existingUser:
                if let poppedProtectWallet = popTo(ProtectWalletViewController.self) {
                    return poppedProtectWallet
                }
            case .sameUserWithoutWallets:
                return popTo(TutorialViewController.self)
            }
        } else if topViewController is RecoveryPhraseViewController {
            return popTo(BackupWalletViewController.self)
        }
        return super.popViewController(animated: animated, completion: completion)
    }
    
    override func willRemove(viewControllers: [UIViewController]) {
        viewControllers.forEach { vc in
            notifyViewControllerWillNavigateBack(vc)
        }
    }
}

// MARK: - CNavigationControllerDelegate
extension OnboardingNavigationController: CNavigationControllerDelegate {
    func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController is TutorialViewController {
            setNewUserOnboardingSubFlow(nil)
        }
        checkSwipeGestureEnabled()
    }
}
 
// MARK: - OnboardingFlowManager
extension OnboardingNavigationController: OnboardingFlowManager {
    func didSetupProtectWallet() {
        func pushBackupWalletsScreen() {
            moveToStep(.backupWallet)
        }
        
        switch onboardingFlow {
        case .newUser(let onboardingSubFlow):
            guard let onboardingSubFlow = onboardingSubFlow else { return }
            
            switch onboardingSubFlow {
            case .create:
                pushBackupWalletsScreen()
            case .restore, .webAccount:
                didFinishOnboarding()
            }
        case .existingUser:
            if iCloudWalletStorage.isICloudAvailable() {
                pushBackupWalletsScreen()
            } else {
                didFinishOnboarding()
            }
        case .sameUserWithoutWallets:
            Debugger.printFailure("Should skip protect steps", critical: true)
        }
    }
    
    func setNewUserOnboardingSubFlow(_ onboardingSubFlow: OnboardingNavigationController.NewUserOnboardingSubFlow?) {
        if case .sameUserWithoutWallets = self.onboardingFlow {
            flow = OnboardingFlow.sameUserWithoutWallets(subFlow: onboardingSubFlow)
        } else {
            flow = OnboardingFlow.newUser(subFlow: onboardingSubFlow)
        }
        UserDefaults.onboardingNavigationInfo?.flow = self.flow
    }
    
    func didFinishOnboarding() {
        moveToStep(.allDone)
        transitionHandler.isInteractionEnabled = false
    }
    
    func moveToStep(_ step: OnboardingNavigationController.OnboardingStep) {
        guard let vc = createOnboardingStep(step) else { return }
        
        UserDefaults.onboardingNavigationInfo?.steps.append(step)
        self.pushViewController(vc, animated: true)
    }
    
    func modifyOnboardingData(modifyingBlock: (inout OnboardingData) -> Void) {
        modifyingBlock(&onboardingData)
        onboardingData.persist()
    }
}

// MARK: - Private methods
private extension OnboardingNavigationController {
    func notifyViewControllerWillNavigateBack(_ viewController: UIViewController) {
        if let stepHandler = stepHandlers.first(where: { $0.stepHandler?.viewController == viewController })?.stepHandler {
            stepHandler.willNavigateBack()
            
            var steps = UserDefaults.onboardingNavigationInfo?.steps ?? []
            if let i = steps.firstIndex(of: stepHandler.onboardingStep) {
                steps.remove(at: i)
            }
            UserDefaults.onboardingNavigationInfo?.steps = steps
        }
    }
    
    func checkSwipeGestureEnabled() {
        guard let topViewController = viewControllers.last else { return }
        
        if topViewController is HappyEndViewController || topViewController is WalletConnectedViewController {
            transitionHandler?.isInteractionEnabled = false
        } else if (topViewController is RecoveryPhraseViewController &&
                  UserDefaults.onboardingNavigationInfo?.steps.contains(.recoveryPhraseConfirmed) == true) ||
        topViewController is LoadingParkedDomainsViewController ||
        topViewController is ParkedDomainsFoundViewController ||
        topViewController is NoParkedDomainsFoundViewController {
            transitionHandler.isInteractionEnabled = false
            DispatchQueue.main.async {
                self.navigationBar.setBackButton(hidden: true)
            }
        } else {
            transitionHandler.isInteractionEnabled = true
        }
    }
}

// MARK: - Setup methods
private extension OnboardingNavigationController {
    func setup() {
        ConfettiImageView.prepareAnimationsAsync()
        
        var onboardingData = OnboardingData.retrieve() ?? .init()
        self.onboardingData = onboardingData
        
        if let info = UserDefaults.onboardingNavigationInfo {
            self.flow = info.flow
            restoreOnboardingSteps(info.steps)
        } else {
            switch flow {
            case .newUser:
                KeychainPrivateKeyStorage.instance.clear(for: .passcode)
                setInitialStep(.newUserTutorial)
            case .sameUserWithoutWallets:
                setInitialStep(.newUserTutorial)
            case .existingUser(let wallets):
                onboardingData.wallets = wallets
                self.onboardingData.wallets = wallets
                KeychainPrivateKeyStorage.instance.clear(for: .passcode)
                setInitialStep(.existingUserTutorial)
            }
            onboardingData.persist()
        }
        checkSwipeGestureEnabled()
    }
    
    func setInitialStep(_ initialStep: OnboardingStep) {
        UserDefaults.onboardingNavigationInfo = .init(flow: flow, steps: [initialStep])
        if let initialViewController = createOnboardingStep(initialStep) {
            viewControllers = [initialViewController]
        }
    }
    
    func restoreOnboardingSteps(_ steps: [OnboardingStep]) {
        if steps.contains(.allDone),
           let viewController = createOnboardingStep(.allDone) {
            viewControllers = [viewController]
            return
        }
        
        var viewControllers = self.viewControllers
        steps.forEach { step in
            if let vc = createOnboardingStep(step) {
                viewControllers.append(vc)
            }
        }
        
        self.viewControllers = viewControllers
        
        self.viewControllers.forEach { vc in
            vc.loadViewIfNeeded()
        }
    }
    
    func createOnboardingStep(_ step: OnboardingStep) -> UIViewController? {
        switch step {
        case .existingUserTutorial:
            let vc = ExistingUsersTutorialViewController.storyboardInstance(from: .tutorial)
            vc.onboardingManager = self
            return vc
        case .newUserTutorial:
            let vc = TutorialViewController.storyboardInstance(from: .tutorial)
            let presenter = TutorialViewPresenter(view: vc, onboardingFlowManager: self)
            vc.presenter = presenter
            return vc
        case .createWallet:
            let vc = CreateWalletViewController.instantiate()
            let presenter = OnboardingCreateWalletPresenter(view: vc,
                                                            onboardingFlowManager: self,
                                                            udWalletsService: udWalletsService)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .protectWallet:
            let vc = ProtectWalletViewController.instantiate()
            let presenter = OnboardingProtectWalletViewPresenter(view: vc,
                                                                 onboardingFlowManager: self,
                                                                 udWalletsService: udWalletsService)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .createPasscode:
            let vc = OnboardingPasscodeViewController.instantiate(mode: .create, onboardingFlowManager: self)
            addStepHandler(vc)
            return vc
        case .confirmPasscode:
            guard let passcodeString = onboardingData.passcode else {
                Debugger.printFailure("No passcode", critical: true)
                return nil }
            let vc = OnboardingPasscodeViewController.instantiate(mode: .confirm(passcode: [Character](passcodeString)), onboardingFlowManager: self)
            addStepHandler(vc)
            return vc
        case .backupWallet:
            let vc = BackupWalletViewController.instantiate()
            let presenter = OnboardingBackupWalletPresenter(view: vc,
                                                            onboardingFlowManager: self,
                                                            networkReachabilityService: appContext.networkReachabilityService,
                                                            udWalletsService: udWalletsService)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .createPassword:
            let vc = CreatePasswordViewController.instantiate()
            let presenter = CreateBackupPasswordOnboardingPresenter(view: vc,
                                                                    onboardingFlowManager: self,
                                                                    udWalletsService: udWalletsService)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .recoveryPhrase:
            guard let recoveryType = self.getWalletRecoveryType() else { return nil }
            
            let vc = RecoveryPhraseViewController.instantiate()
            let presenter = OnboardingRecoveryPhrasePresenter(view: vc,
                                                              recoveryType: recoveryType,
                                                              mode: .manual,
                                                              onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .confirmWords:
            let vc = ConfirmWordsViewController.instantiate()
            let presenter = OnboardingConfirmWordsPresenter(view: vc, onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .recoveryPhraseConfirmed:
            guard let recoveryType = self.getWalletRecoveryType() else { return nil }
            
            let vc = RecoveryPhraseViewController.instantiate()
            let presenter = OnboardingRecoveryPhrasePresenter(view: vc,
                                                              recoveryType: recoveryType,
                                                              mode: .iCloud(password: onboardingData.backupPassword),
                                                              onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            navigationBar.setBackButton(hidden: true)
            return vc
        case .restoreWallet:
            let vc = RestoreWalletViewController.instantiate()
            vc.onboardingFlowManager = self
            addStepHandler(vc)
            return vc
        case .enterBackup:
            let vc = EnterBackupViewController.instantiate()
            let presenter = EnterBackupOnboardingPresenter(view: vc,
                                                           onboardingFlowManager: self,
                                                           udWalletsService: udWalletsService)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .addManageWallet:
            let vc = AddWalletViewController.nibInstance()
            let presenter = OnboardingAddWalletPresenter(view: vc,
                                                         walletType: .verified,
                                                         udWalletsService: udWalletsService,
                                                         onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .addWatchWallet:
            let vc = AddWalletViewController.nibInstance()
            let presenter = OnboardingAddWalletPresenter(view: vc,
                                                         walletType: .readOnly,
                                                         udWalletsService: udWalletsService,
                                                         onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .connectExternalWallet:
            let vc = ConnectExternalWalletViewController.nibInstance()
            let presenter = OnboardingConnectExternalWalletPresenter(view: vc,
                                                                     onboardingFlowManager: self,
                                                                     udWalletsService: udWalletsService,
                                                                     walletConnectServiceV2: walletConnectServiceV2)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .externalWalletConnected:
            let vc = WalletConnectedViewController.instantiate()
            let presenter = OnboardingWalletConnectedPresenter(view: vc, onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .allDone:
            let vc = HappyEndViewController.instance()
            return vc
        case .loginWithWebsite:
            let vc = LoginViewController.nibInstance()
            let presenter = LoginOnboardingViewPresenter(view: vc,
                                                         onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .loadingParkedDomains:
            let vc = LoadingParkedDomainsViewController.nibInstance()
            let presenter = LoadingParkedDomainsOnboardingViewPresenter(view: vc,
                                                                        onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .loginWithEmailAndPassword:
            let vc = LoginWithEmailViewController.nibInstance()
            let presenter = LoginWithEmailOnboardingViewPresenter(view: vc,
                                                                  onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .noParkedDomains:
            let vc = NoParkedDomainsFoundViewController.nibInstance()
            let presenter = NoParkedDomainsFoundOnboardingViewPresenter(view: vc,
                                                                        onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        case .parkedDomainsFound:
            guard let parkedDomains = onboardingData.parkedDomains else {
                Debugger.printFailure("Failed to get parked domains from onboarding data", critical: true)
                return nil }
            
            let vc = ParkedDomainsFoundViewController.nibInstance()
            let presenter = ParkedDomainsFoundOnboardingViewPresenter(view: vc,
                                                                      domains: parkedDomains,
                                                                      onboardingFlowManager: self)
            addStepHandler(presenter)
            vc.presenter = presenter
            return vc
        }
    }
 
    func addStepHandler(_ stepHandler: OnboardingStepHandler) {
        stepHandlers.append(.init(stepHandler: stepHandler))
    }
    
    func getWalletRecoveryType() -> UDWallet.RecoveryType? {
        guard let recoveryType = self.onboardingData.wallets.first?.recoveryType else {
            Debugger.printFailure("There's no wallet or it's type is not supported to show recovery phrase during onboarding",
                                  critical: true)
            didFinishOnboarding()
            return nil
        }
        return recoveryType
    }
}

extension OnboardingNavigationController {
    enum OnboardingFlow: Codable {
        case newUser(subFlow: NewUserOnboardingSubFlow?), existingUser(wallets: [UDWallet])
        case sameUserWithoutWallets(subFlow: NewUserOnboardingSubFlow?)
    }
    
    enum NewUserOnboardingSubFlow: Int, Codable {
        case create, restore, webAccount
    }
    
    enum OnboardingStep: Int, Codable {
        case newUserTutorial = 0
        
        case createWallet = 1
        case protectWallet = 2
        case createPasscode = 3
        case confirmPasscode = 4
        case backupWallet = 5
        case createPassword = 6
        case recoveryPhrase = 7
        case confirmWords = 8
        case recoveryPhraseConfirmed = 9
        
        case restoreWallet = 10
        case enterBackup = 11
        case addManageWallet = 12
        case addWatchWallet = 13
        case connectExternalWallet = 14
        case externalWalletConnected = 15
        
        case allDone = 16
        
        case existingUserTutorial = 17
        
        case loginWithWebsite = 18
        case loadingParkedDomains = 19
        case loginWithEmailAndPassword = 20
        case noParkedDomains = 21
        case parkedDomainsFound = 22
    }
    
    struct OnboardingNavigationInfo: Codable, CustomStringConvertible {
        var flow: OnboardingFlow
        var steps: [OnboardingStep]
        
        var description: String { "\n\nOnboardingData\nFlow: \(flow)\nSteps: \(steps.map({ $0.rawValue} ))\n\n" }
    }
}
