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
    
    private var mode: Mode!
    private var didTransferDomain = false
    var transferResultCallback: TransferResultCallback?
    
    convenience init(mode: Mode) {
        self.init()
        self.mode = mode
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
            self.dismiss(result: didTransferDomain ?.transferred : .cancelled)
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
        case .confirmedTransferOf(let domainDisplayInfo, let recipient, let configuration ):
            guard let topViewController = self.topViewController as? PaymentConfirmationDelegate else {
                dismiss(result: .cancelled)
                Debugger.printFailure("Failed to get payment confirmation delegate to set RR", critical: true)
                return
            }
            let domain = try await appContext.dataAggregatorService.getDomainWith(name: domainDisplayInfo.name)
            try await appContext.domainTransferService.transferDomain(domain: domain,
                                                                      to: recipient.ownerAddress,
                                                                      configuration: configuration,
                                                                      paymentConfirmationDelegate: topViewController)
            Task.detached {
                await appContext.dataAggregatorService.aggregateData(shouldRefreshPFP: false)
            }
            moveToStep(.transferInProgressOf(domain: domainDisplayInfo))
        case .transactionFinished:
            dismiss(result: .transferred)
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
        viewController == rootViewController ||
        viewController is TransactionInProgressViewController
    }
    
    func dismiss(result: Result) {
        view.endEditing(true)
        transferResultCallback?(result)
        dismiss(animated: true)
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
        switch step {
        case .selectRecipientFor(let domain):
            let vc = EnterValueViewController.nibInstance()
            let presenter = EnterTransferDomainRecipientValuePresenter(view: vc,
                                                                       domain: domain,
                                                                       transferDomainFlowManager: self)
            vc.presenter = presenter
            return vc
        case .reviewAndConfirmTransferOf(let domain, let recipient):
            let vc = ReviewAndConfirmTransferViewController.nibInstance()
            let presenter = ReviewAndConfirmTransferViewPresenter(view: vc,
                                                                  domain: domain,
                                                                  recipient: recipient,
                                                                  mode: mode,
                                                                  transferDomainFlowManager: self)
            
            vc.presenter = presenter
            return vc
        case .transferInProgressOf(let domain):
            self.didTransferDomain = true
            return UDRouter().buildTransferInProgressModule(domain: domain,
                                                            transferDomainFlowManager: self)
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
        case confirmedTransferOf(domain: DomainDisplayInfo, recipient: RecipientType, configuration: TransferDomainConfiguration)
        case transactionFinished
    }
    
    enum Result {
        case cancelled
        case transferred
    }
    
    enum RecipientType: Hashable {
        case walletAddress(String)
        case resolvedDomain(name: String, walletAddress: String)
        
        var visibleName: String {
            switch self {
            case .walletAddress(let address):
                return address.walletAddressTruncated
            case .resolvedDomain(let name, _):
                return name
            }
        }
        
        var ownerAddress: String {
            switch self {
            case .walletAddress(let address), .resolvedDomain(_, let address):
                return address
            }
        }
    }
}
