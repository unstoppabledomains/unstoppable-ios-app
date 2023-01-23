//
//  CreateLocalWalletNavigationController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

protocol AddWalletFlowManager: AnyObject {
    var wallet: UDWallet? { get set }
    var mode: AddWalletNavigationController.Mode { get }
    
    func moveToStep(_ step: AddWalletNavigationController.Step)
    func didFinishCreateWalletFlow()
}

final class AddWalletNavigationController: UINavigationController {
    
    typealias WalletAddedCallback = ((Result)->())
    
    private(set) var mode: Mode = .createLocal
    var wallet: UDWallet?
    var walletAddedCallback: WalletAddedCallback?
    private var isSwipeGesture = false
    
    convenience init(mode: Mode) {
        self.init()
        self.mode = mode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        isSwipeGesture = false
        guard let topViewController = viewControllers.last else {
            return super.popViewController(animated: animated)
        }
        
        DispatchQueue.main.async { [weak self] in
            if self?.isLastViewController(topViewController) == true {
                if self?.isSwipeGesture == false {
                    self?.dismiss(animated: true) { [weak self] in
                        if let wallet = self?.wallet {
                            self?.walletAddedCallback?(.created(wallet))
                        }
                    }
                } else {
                    self?.viewControllers.append(topViewController)
                }
            }
        }
        
        if isLastViewController(topViewController) {
            return super.popViewController(animated: false)
        }
        
        return super.popViewController(animated: animated)
    }
    
}

// MARK: - CreateLocalWalletFlowManager
extension AddWalletNavigationController: AddWalletFlowManager {
    func moveToStep(_ step: Step) {
        guard let vc = createStep(step) else { return }
       
        switch mode {
        case .createLocal, .importExternal:
            if vc is BackupWalletViewController  {
                DispatchQueue.main.async {
                    let newVC = BaseViewController()
                    self.viewControllers[0] = newVC
                    newVC.loadViewIfNeeded()
                }
            }
        }
        
        self.pushViewController(vc, animated: true)
    }
    
    func didFinishCreateWalletFlow() {
        dismiss(animated: true) { [weak self] in
            if let wallet = self?.wallet {
                self?.walletAddedCallback?(.createdAndBackedUp(wallet))
            }
        }
    }
}

// MARK: - Private methods
private extension AddWalletNavigationController {
    @objc private func handleSwipeGesture(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            isSwipeGesture = true
            if let _ = topViewController as? CreateWalletViewController {
                gesture.isEnabled = false
                gesture.isEnabled = true
            }
        default:
            return
        }
    }
    
    func isLastViewController(_ viewController: UIViewController) -> Bool {
        switch mode {
        case .createLocal:
            return viewController is BackupWalletViewController
        case .importExternal:
            return viewController is BackupWalletViewController || viewController is AddWalletViewController
        }
    }
}

// MARK: - Setup methods
private extension AddWalletNavigationController {
    func setup() {
        isModalInPresentation = true
        interactivePopGestureRecognizer?.addTarget(self, action: #selector(handleSwipeGesture))
        
        switch mode {
        case .createLocal:
            if let initialViewController = createStep(.createWallet) {
                viewControllers = [initialViewController]
            }
        case .importExternal(let walletType):
            if let initialViewController = createStep(.importWallet(walletType: walletType)) {
                let emptyVC = BaseViewController()
                viewControllers = [emptyVC, initialViewController]
                emptyVC.loadViewIfNeeded()
            }
        }
    }
    
    func createStep(_ step: Step) -> UIViewController? {
        switch step {
        case .createWallet:
            let vc = CreateWalletViewController.instantiate()
            let presenter = CreateLocalWalletPresenter(view: vc,
                                                       addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        case .backupWallet:
            let vc = BackupWalletViewController.instantiate()
            let presenter = BackupCreatedLocalWalletPresenter(view: vc,
                                                              addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        case .createPassword:
            let vc = CreatePasswordViewController.instantiate()
            let presenter = CreateBackupPasswordCreatedLocalWalletPresenter(view: vc,
                                                                            addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        case .recoveryPhrase:
            let vc = RecoveryPhraseViewController.instantiate()
            let presenter = CreateLocalWalletRecoveryPhrasePresenter(view: vc,
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
            let vc = RecoveryPhraseViewController.instantiate()
            let presenter = CreateLocalWalletRecoveryPhrasePresenter(view: vc,
                                                                     mode: .iCloud(password: password),
                                                                     addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        case .enterBackup:
            let vc = EnterBackupViewController.instantiate()
            let presenter = CreateLocalWalletEnterBackupPresenter(view: vc,
                                                                  addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        case .importWallet(let walletType):
            let vc = AddWalletViewController.instantiate()
            let presenter = ImportNewWalletPresenter(view: vc,
                                                     walletType: walletType,
                                                     addWalletFlowManager: self)
            vc.presenter = presenter
            return vc
        }
    }
    
}

extension AddWalletNavigationController {
    enum Mode {
        case createLocal
        case importExternal(walletType: BaseAddWalletPresenter.RestorationWalletType)
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
    }
    
    enum Result {
        case created(_ wallet: UDWallet)
        case createdAndBackedUp(_ wallet: UDWallet)
    }
}
