//
//  TransferDomainNavigationManager.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2023.
//

import UIKit

protocol TransferDomainFlowManager: AnyObject {
    func handle(action: TransferDomainNavigationManager.Action) async throws
}

final class TransferDomainNavigationManager: CNavigationController {
    
    typealias TransferResultCallback = ((Result)->())
    
    private let dataAggregatorService: DataAggregatorServiceProtocol = appContext.dataAggregatorService
    private let udWalletsService: UDWalletsServiceProtocol = appContext.udWalletsService
    private var mode: Mode!
    private var wallet: UDWallet?
    private var walletInfo: WalletDisplayInfo?
    var transferResultCallback: TransferResultCallback?
    
    convenience init(mode: Mode,
                     wallet: UDWallet,
                     walletInfo: WalletDisplayInfo) {
        self.init()
        self.mode = mode
        self.wallet = wallet
        self.walletInfo = walletInfo
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presentationController?.delegate = self
    }
    
    override func popViewController(animated: Bool, completion: (()->())? = nil) -> UIViewController? {
        guard let topViewController = self.topViewController else {
            return super.popViewController(animated: animated)
        }
        
        if self.isLastViewController(topViewController) {
            self.dismiss(result: .cancelled)
        }
        
        return super.popViewController(animated: animated)
    }
    
}

// MARK: - TransferDomainFlowManager
extension TransferDomainNavigationManager: TransferDomainFlowManager {
    func handle(action: Action) async throws {
        switch action {
        case .recipientSelected(let recipient, let domain):
            moveToStep(.reviewAndConfirmTransferOf(domain: domain, recipient: recipient))
        case .confirmedTransferOf(let domain, let recipient):
            Void()
//            guard let topViewController = self.topViewController as? PaymentConfirmationDelegate else {
//                dismiss(result: .cancelled)
//                Debugger.printFailure("Failed to get payment confirmation delegate to set RR", critical: true)
//                return
//            }
//            let domain = try await dataAggregatorService.getDomainWith(name: domainDisplayInfo.name)
//            try await udWalletsService.setReverseResolution(to: domain,
//                                                            paymentConfirmationDelegate: topViewController)
//            dismiss(result: .transferred(domain: domainDisplayInfo))
        }
    }
}

// MARK: - CNavigationControllerDelegate
extension TransferDomainNavigationManager: CNavigationControllerDelegate {
    func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool) {
        checkSwipeGestureEnabled()
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension TransferDomainNavigationManager: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        transferResultCallback?(.cancelled)
    }
}

// MARK: - Private methods
private extension TransferDomainNavigationManager {
    func moveToStep(_ step: Step) {
        guard let vc = createStep(step) else { return }
        
        self.pushViewController(vc, animated: true)
    }
    
    func checkSwipeGestureEnabled() {
        guard let topViewController = self.topViewController else { return }
        
        if topViewController is TransactionInProgressViewController {
            transitionHandler?.isInteractionEnabled = false
        } else {
            transitionHandler?.isInteractionEnabled = !isLastViewController(topViewController)
        }
    }
    
    func isLastViewController(_ viewController: UIViewController) -> Bool {
        viewController == rootViewController
    }
    
    func dismiss(result: Result) {
        view.endEditing(true)
        dismiss(animated: true) { [weak self] in
            self?.transferResultCallback?(result)
        }
    }
}

// MARK: - Setup methods
private extension TransferDomainNavigationManager {
    func setup() {
        isModalInPresentation = true
        
        switch mode {
        case .singleDomainTransfer(let domain):
            if let initialViewController = createStep(.selectRecipientFor(domain: domain)) {
                setViewControllers([initialViewController], animated: false)
            }
        case .none:
            Debugger.printFailure("Transfer mode is not set", critical: true)
            return
        }
        
        setupBackButtonAlwaysVisible()
        checkSwipeGestureEnabled()
    }
    
    func setupBackButtonAlwaysVisible() {
        navigationBar.alwaysShowBackButton = true
        navigationBar.setBackButton(hidden: false)
    }
    
    func createStep(_ step: Step) -> UIViewController? {
        guard let wallet = self.wallet,
              let walletInfo = self.walletInfo else {
            Debugger.printFailure("Wallet is not set for RR setup", critical: true)
            return nil
        }
       
        switch step {
        case .selectRecipientFor(let domain):
            let vc = EnterValueViewController.nibInstance()
            let presenter = EnterTransferDomainRecipientValuePresenter(view: vc,
                                                                       domain: domain,
                                                                       transferDomainFlowManager: self)
            vc.presenter = presenter
            return vc
        case .reviewAndConfirmTransferOf(let mode, let recipient):
            return nil
//            let vc = ChooseReverseResolutionDomainViewController.nibInstance()
//            let presenter: ChooseReverseResolutionDomainViewPresenterProtocol
//
//            switch mode {
//            case .chooseFirst:
//                presenter = SelectWalletsReverseResolutionDomainViewPresenter(view: vc,
//                                                                              wallet: wallet,
//                                                                              walletInfo: walletInfo,
//                                                                              setupWalletsReverseResolutionFlowManager: self,
//                                                                              dataAggregatorService: dataAggregatorService)
//            case .changeExisting(let currentDomain):
//                presenter = ChangeWalletsReverseResolutionDomainViewPresenter(view: vc,
//                                                                              wallet: wallet,
//                                                                              walletInfo: walletInfo,
//                                                                              currentDomain: currentDomain,
//                                                                              setupWalletsReverseResolutionFlowManager: self,
//                                                                              dataAggregatorService: dataAggregatorService)
//            }
//
//            vc.presenter = presenter
//            return vc
        case .transferInProgressOf(let domain):
            return nil
        }
    }
}

extension TransferDomainNavigationManager {
    enum Mode {
        case singleDomainTransfer(domain: DomainDisplayInfo)
    }
    
    enum Step {
        case selectRecipientFor(domain: DomainDisplayInfo)
        case reviewAndConfirmTransferOf(domain: DomainDisplayInfo, recipient: RecipientType)
        case transferInProgressOf(domain: DomainDisplayInfo)
    }
    
    enum Action {
        case recipientSelected(recipient: RecipientType, forDomain: DomainDisplayInfo)
        case confirmedTransferOf(domain: DomainDisplayInfo, recipient: RecipientType)
    }
    
    enum Result {
        case cancelled
        case transferred(domain: DomainDisplayInfo)
    }
    
    enum RecipientType {
        case walletAddress(String)
        case resolvedDomain(name: String, walletAddress: String)
    }
}
