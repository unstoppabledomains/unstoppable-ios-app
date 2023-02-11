//
//  CreateLocalWalletNavigationController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol AddWalletFlowManager: AnyObject {
    var wallet: UDWallet? { get set }
    
    func moveToStep(_ step: AddWalletNavigationController.Step)
    func didFinishAddWalletFlow()
}

final class AddWalletNavigationController: CNavigationController {
    
    typealias WalletAddedCallback = ((Result)->())
    
    private let networkReachabilityService: NetworkReachabilityServiceProtocol? = appContext.networkReachabilityService
    private let udWalletsService: UDWalletsServiceProtocol = appContext.udWalletsService
    private let walletConnectClientService: WalletConnectClientServiceProtocol = appContext.walletConnectClientService
    private let walletConnectClientServiceV2: WalletConnectClientServiceV2Protocol = appContext.walletConnectClientServiceV2
    private var mode: Mode = .createLocal
    var wallet: UDWallet?
    var walletAddedCallback: WalletAddedCallback?
    
    convenience init(mode: Mode) {
        self.init()
        self.mode = mode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        setup()
    }
    
    override func popViewController(animated: Bool, completion: (()->())? = nil) -> UIViewController? {
        guard let topViewController = self.topViewController else {
            return super.popViewController(animated: animated)
        }
        
        if self.isLastViewController(topViewController) {
            if let wallet = self.wallet {
                if case .createLocal = self.mode {
                    udWalletsService.remove(wallet: wallet)
                    self.dismiss(result: .cancelled)
                } else {
                    self.dismiss(result: .created(wallet))
                }
            } else {
                self.dismiss(result: .cancelled)
            }
        }
        
        return super.popViewController(animated: animated)
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        navigationBar.navBarContentView.backButton.accessibilityIdentifier = "Add Wallet Navigation Back Button"
    }
    
}

// MARK: - CreateLocalWalletFlowManager
extension AddWalletNavigationController: AddWalletFlowManager {
    func moveToStep(_ step: Step) {
        guard let vc = createStep(step) else { return }
       
        switch mode {
        case .createLocal, .importExternal:
            if vc is BackupWalletViewController  {
                setupBackButtonAlwaysVisible()
                DispatchQueue.main.async {
                    self.viewControllers.removeFirst()
                }
            }
        case .connectExternal:
            Void()
        }
        
        self.pushViewController(vc, animated: true)
    }
    
    func didFinishAddWalletFlow() {
        guard let wallet = self.wallet else {
            dismiss(result: .cancelled)
            Debugger.printFailure("Did finish add wallet without wallet", critical: true)
            return
        }
        
        dismiss(result: .createdAndBackedUp(wallet))
    }
}
 
// MARK: - CNavigationControllerDelegate
extension AddWalletNavigationController: CNavigationControllerDelegate {
    func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool) {
        checkSwipeGestureEnabled()
    }
}

// MARK: - Private methods
private extension AddWalletNavigationController {
    func checkSwipeGestureEnabled() {
        guard let topViewController = self.topViewController else { return }
        
        transitionHandler?.isInteractionEnabled = !isLastViewController(topViewController)
    }
    
    func isLastViewController(_ viewController: UIViewController) -> Bool {
        switch mode {
        case .createLocal:
            return viewController is BackupWalletViewController
        case .importExternal:
            return viewController is BackupWalletViewController || viewController is AddWalletViewController
        case .connectExternal:
            return true
        }
    }
    
    func dismiss(result: Result) {
        UDVibration.buttonTap.vibrate()
        view.endEditing(true)
        dismiss(animated: true) { [weak self] in
            self?.walletAddedCallback?(result)
        }
    }
}

// MARK: - Setup methods
private extension AddWalletNavigationController {
    func setup() {
        isModalInPresentation = true
        
        switch mode {
        case .createLocal:
            if let initialViewController = createStep(.createWallet) {
                setViewControllers([initialViewController], animated: false)
            }
        case .importExternal(let walletType):
            if let initialViewController = createStep(.importWallet(walletType: walletType)) {
                setupBackButtonAlwaysVisible()
                setViewControllers([initialViewController], animated: false)
            }
        case .connectExternal:
            if let initialViewController = createStep(.connectExternalWallet) {
                setupBackButtonAlwaysVisible()
                setViewControllers([initialViewController], animated: false)
            }
        }
        
        checkSwipeGestureEnabled()
    }
    
    func setupBackButtonAlwaysVisible() {
        navigationBar.alwaysShowBackButton = true
        navigationBar.setBackButton(hidden: false)
    }
    
    func createStep(_ step: Step) -> UIViewController? {
        switch step {
        case .createWallet:
            let vc = CreateWalletViewController.instantiate()
            let presenter = CreateLocalWalletPresenter(view: vc,
                                                       addWalletFlowManager: self,
                                                       udWalletsService: udWalletsService)
            vc.presenter = presenter
            return vc
        case .backupWallet:
            let vc = BackupWalletViewController.instantiate()
            let mode: BackupCreatedLocalWalletPresenter.WalletSource
            switch self.mode {
            case .createLocal:
                mode = .locallyCreated
            case .importExternal, .connectExternal:
                mode = .imported
            }
            let presenter = BackupCreatedLocalWalletPresenter(view: vc,
                                                              addWalletFlowManager: self,
                                                              walletSource: mode,
                                                              networkReachabilityService: networkReachabilityService)
            vc.presenter = presenter
            return vc
        case .createPassword:
            let vc = CreatePasswordViewController.instantiate()
            let presenter = CreateBackupPasswordForNewLocalWalletPresenter(view: vc,
                                                                     addWalletFlowManager: self,
                                                                           udWalletsService: udWalletsService)
            vc.presenter = presenter
            return vc
        case .recoveryPhrase:
            guard let recoveryType = getWalletRecoveryType() else { return nil }
            
            let vc = RecoveryPhraseViewController.instantiate()
            let presenter = CreateLocalWalletRecoveryPhrasePresenter(view: vc,
                                                                     recoveryType: recoveryType,
                                                                     mode: .manual,
                                                                     addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        case .confirmWords:
            let vc = ConfirmWordsViewController.instantiate()
            let presenter = CreateLocalWalletRecoveryWordsPresenter(view: vc,
                                                                    addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        case .recoveryPhraseConfirmed(let password):
            guard let recoveryType = getWalletRecoveryType() else { return nil }

            let vc = RecoveryPhraseViewController.instantiate()
            let presenter = CreateLocalWalletRecoveryPhrasePresenter(view: vc,
                                                                     recoveryType: recoveryType,
                                                                     mode: .iCloud(password: password),
                                                                     addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        case .enterBackup:
            guard let wallet = self.wallet else { return nil }
            
            let vc = EnterBackupViewController.instantiate()
            let presenter = EnterBackupCreateLocalWalletPresenter(view: vc,
                                                                  udWalletsService: udWalletsService,
                                                                  wallet: wallet,
                                                                  addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        case .importWallet(let walletType):
            let vc = AddWalletViewController.nibInstance()
            let presenter = ImportNewWalletPresenter(view: vc,
                                                     walletType: walletType,
                                                     udWalletsService: udWalletsService,
                                                     addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        case .connectExternalWallet:
            let vc = ConnectExternalWalletViewController.nibInstance()
            let presenter = ConnectNewExternalWalletPresenter(view: vc,
                                                              addWalletFlowManager: self,
                                                              udWalletsService: udWalletsService,
                                                              walletConnectClientService: walletConnectClientService,
                                                              walletConnectClientServiceV2: walletConnectClientServiceV2)
            vc.presenter = presenter
            return vc
        case .externalWalletConnected:
            let vc = WalletConnectedViewController.instantiate()
            let presenter = NewExternalWalletConnectedPresenter(view: vc,
                                                                addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        }
    }
    
    func getWalletRecoveryType() -> UDWallet.RecoveryType? {
        guard let recoveryType = self.wallet?.recoveryType else {
            Debugger.printFailure("There's no wallet or it's type is not supported to show recovery phrase while adding new wallet",
                                  critical: true)
            didFinishAddWalletFlow()
            return nil
        }
        return recoveryType
    }
}

extension AddWalletNavigationController {
    enum Mode {
        case createLocal
        case importExternal(walletType: BaseAddWalletPresenter.RestorationWalletType)
        case connectExternal
    }
    
    enum Step: Codable {
        case createWallet
        case backupWallet
        case createPassword
        case recoveryPhrase
        case confirmWords
        case recoveryPhraseConfirmed(password: String)
        case enterBackup
        case importWallet(walletType: BaseAddWalletPresenter.RestorationWalletType)
        case connectExternalWallet
        case externalWalletConnected
    }
    
    enum Result {
        case cancelled
        case created(_ wallet: UDWallet)
        case createdAndBackedUp(_ wallet: UDWallet)
    }
}
