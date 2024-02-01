//
//  SetupWalletsReverseResolutionNavigationManager.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.09.2022.
//

import UIKit

protocol SetupWalletsReverseResolutionFlowManager: AnyObject {
    func handle(action: SetupWalletsReverseResolutionNavigationManager.Action) async throws
}

final class SetupWalletsReverseResolutionNavigationManager: CNavigationController {
    
    typealias ReverseResolutionSetCallback = ((Result)->())
    
    private let dataAggregatorService: DataAggregatorServiceProtocol = appContext.dataAggregatorService
    private let udWalletsService: UDWalletsServiceProtocol = appContext.udWalletsService
    private var mode: Mode = .chooseFirstDomain
    private var wallet: WalletEntity?
    var reverseResolutionSetCallback: ReverseResolutionSetCallback?
    
    convenience init(mode: Mode,
                     wallet: WalletEntity) {
        self.init()
        self.mode = mode
        self.wallet = wallet
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
        guard self.topViewController != nil else {
            return super.popViewController(animated: animated)
        }
        
        
        return super.popViewController(animated: animated)
    }
    
}

// MARK: - SetupWalletsReverseResolutionFlowManager
extension SetupWalletsReverseResolutionNavigationManager: SetupWalletsReverseResolutionFlowManager {
    func handle(action: Action) async throws {
        switch action {
        case .continueReverseResolutionSetup:
            moveToStep(.chooseDomainForReverseResolution(mode: .chooseFirstDomain))
        case .didSelectDomainForReverseResolution(let domainDisplayInfo):
            guard let topViewController = self.topViewController as? PaymentConfirmationDelegate else {
                dismiss(result: .cancelled)
                Debugger.printFailure("Failed to get payment confirmation delegate to set RR", critical: true)
                return
            }
            let domain = domainDisplayInfo.toDomainItem()
            try await udWalletsService.setReverseResolution(to: domain,
                                                            paymentConfirmationDelegate: topViewController)
            dismiss(result: .set(domain: domainDisplayInfo))
        case .didFailToSetupRequiredReverseResolution:
            dismiss(result: .failed)
        }
    }
}

// MARK: - CNavigationControllerDelegate
extension SetupWalletsReverseResolutionNavigationManager: CNavigationControllerDelegate {
    func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool) {
        checkSwipeGestureEnabled()
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension SetupWalletsReverseResolutionNavigationManager: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        reverseResolutionSetCallback?(.cancelled)
    }
}

// MARK: - Private methods
private extension SetupWalletsReverseResolutionNavigationManager {
    func moveToStep(_ step: Step) {
        guard let vc = createStep(step) else { return }
        
        self.pushViewController(vc, animated: true)
    }
    
    func checkSwipeGestureEnabled() {
        guard let topViewController = self.topViewController else { return }
        
        transitionHandler?.isInteractionEnabled = !isLastViewController(topViewController)
    }
    
    func isLastViewController(_ viewController: UIViewController) -> Bool {
        viewController == rootViewController
    }
    
    func dismiss(result: Result) {
        view.endEditing(true)
        dismiss(animated: true) { [weak self] in
            self?.reverseResolutionSetCallback?(result)
        }
    }
}

// MARK: - Setup methods
private extension SetupWalletsReverseResolutionNavigationManager {
    func setup() {
        
        switch mode {
        case .chooseFirstDomain:
            isModalInPresentation = true
            if let initialViewController = createStep(.setupReverseResolutionInfo) {
                setViewControllers([initialViewController], animated: false)
            }
        case .changeDomain, .chooseFirstForMessaging:
            if let initialViewController = createStep(.chooseDomainForReverseResolution(mode: mode)) {
                setViewControllers([initialViewController], animated: false)
            }
        }
        
        checkSwipeGestureEnabled()
    }
    
    func createStep(_ step: Step) -> UIViewController? {
        guard let wallet = self.wallet else {
            Debugger.printFailure("Wallet is not set for RR setup", critical: true)
            return nil
        }
        
        switch step {
        case .setupReverseResolutionInfo:
            let vc = SetupReverseResolutionViewController.nibInstance()
            let presenter = SetupWalletsReverseResolutionPresenter(view: vc,
                                                                   wallet: wallet,
                                                                   udWalletsService: udWalletsService,
                                                                   setupWalletsReverseResolutionFlowManager: self)
            vc.presenter = presenter
            return vc
        case .chooseDomainForReverseResolution(let mode ):
            let vc = ChooseReverseResolutionDomainViewController.nibInstance()
            let presenter: ChooseReverseResolutionDomainViewPresenterProtocol
            
            switch mode {
            case .chooseFirstDomain:
                presenter = SelectWalletsReverseResolutionDomainViewPresenter(view: vc,
                                                                              wallet: wallet,
                                                                              useCase: .default,
                                                                              setupWalletsReverseResolutionFlowManager: self,
                                                                              dataAggregatorService: dataAggregatorService)
            case .chooseFirstForMessaging:
                presenter = SelectWalletsReverseResolutionDomainViewPresenter(view: vc,
                                                                              wallet: wallet,
                                                                              useCase: .messaging,
                                                                              setupWalletsReverseResolutionFlowManager: self,
                                                                              dataAggregatorService: dataAggregatorService)
            case .changeDomain(let currentDomain):
                presenter = ChangeWalletsReverseResolutionDomainViewPresenter(view: vc,
                                                                              wallet: wallet,
                                                                              currentDomain: currentDomain,
                                                                              setupWalletsReverseResolutionFlowManager: self,
                                                                              dataAggregatorService: dataAggregatorService)
            }
            
            vc.presenter = presenter
            return vc
        }
    }
}

extension SetupWalletsReverseResolutionNavigationManager {
    enum Mode {
        case chooseFirstDomain
        case chooseFirstForMessaging
        case changeDomain(currentDomain: DomainDisplayInfo)
    }
    
    enum Step {
        case setupReverseResolutionInfo
        case chooseDomainForReverseResolution(mode: Mode)
    }
    
    enum Action {
        case continueReverseResolutionSetup
        case didSelectDomainForReverseResolution(_ domain: DomainDisplayInfo)
        case didFailToSetupRequiredReverseResolution
    }
    
    enum Result {
        case cancelled
        case set(domain: DomainDisplayInfo)
        case failed
    }
    
    enum ChooseDomainForReverseResolutionMode {
        case chooseFirst, changeExisting(currentDomain: DomainDisplayInfo)
    }
}
