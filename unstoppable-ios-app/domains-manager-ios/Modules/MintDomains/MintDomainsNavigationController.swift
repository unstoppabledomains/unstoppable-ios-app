//
//  MintDomainsNavigationController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.05.2022.
//

import UIKit

@MainActor
protocol MintDomainsFlowManager: AnyObject {
    func handle(action: MintDomainsNavigationController.Action) async throws
}

@MainActor
final class MintDomainsNavigationController: CNavigationController {
    
    typealias DomainsMintedCallback = ((Result)->())
    typealias MintDomainsResult = Result

    private var mintedDomains: [DomainItem] = []
    private var mode: Mode = .default
    private var mintingData: MintingData = MintingData()
    
    private let dataAggregatorService: DataAggregatorServiceProtocol = appContext.dataAggregatorService
    private let userDataService: UserDataServiceProtocol = appContext.userDataService
    private let domainsService: UDDomainsServiceProtocol = appContext.udDomainsService
    private let walletsService: UDWalletsServiceProtocol = appContext.udWalletsService
    private let transactionsService: DomainTransactionsServiceProtocol = appContext.domainTransactionsService
    private let notificationsService: NotificationsServiceProtocol = appContext.notificationsService

    var domainsMintedCallback: DomainsMintedCallback?

    convenience init(mode: Mode, mintedDomains: [DomainItem]) {
        self.init()
        self.mode = mode
        self.mintedDomains = mintedDomains
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
        
        if topViewController is EnterEmailViewController || topViewController is WhatIsMintingViewController{
            return cNavigationController?.popViewController(animated: true)
        } else if topViewController is MintDomainsConfigurationViewController {
            return super.popTo(EnterEmailViewController.self)
        } else if topViewController is NoDomainsToMintViewController {
            dismiss(result: .noDomainsToMint)
            return nil
        }
        return super.popViewController(animated: animated, completion: completion)
    }
}

// MARK: - MintDomainsFlowManager
extension MintDomainsNavigationController: MintDomainsFlowManager {
    func handle(action: Action) async throws {
        switch action {
        case .getStartedAfterTutorial(let shouldShowMintingTutorialInFuture):
            UserDefaults.shouldShowMintingTutorial = shouldShowMintingTutorialInFuture
            moveToStep(.enterEmail(User.instance.email, shouldAutoSendEmail: false))
        case .sentCodeToEmail(let email):
            User.instance.email = email
            mintingData.email = email
            moveToStep(.enterEmailVerificationCode(email: email, code: nil))
        case .didReceiveUnMintedDomains(let unMintedDomains, let email, let code):
            mintingData.code = code
            if unMintedDomains.isEmpty {
                moveToStep(.noDomainsToMint(email: email, code: code))
            } else {
                moveToStep(.selectDomainsToMint(domains: unMintedDomains))
            }
        case .noDomainsGotItPressed:
            dismiss(result: .noDomainsToMint)
        case .noDomainsImportWalletPressed:
            dismiss(result: .importWallet)
        case .domainsPurchased(let details):
            dismiss(result: .domainsPurchased(details: details))
        case .didSelectDomainsToMint(let domains, let wallet):
            self.mintingData.wallet = wallet
            let primaryDomain = mintedDomains.first(where: { $0.isPrimary })
            if domains.count == 1 {
                if primaryDomain == nil {
                    try await startMinting(domains: domains, primaryDomain: domains[0])
                } else {
                    moveToStep(.choosePrimaryDomain(domains: domains, primaryDomain: primaryDomain))
                }
            } else {
                moveToStep(.choosePrimaryDomain(domains: domains, primaryDomain: primaryDomain))
            }
        case .didSelectDomainToMint(let domain, let  wallet, let isPrimary):
            mintingData.wallet = wallet
            try await startMinting(domains: [domain], primaryDomain: isPrimary ? domain : nil)
        case .didConfirmDomainsToMint(let domains, let primaryDomain):
            try await startMinting(domains: domains, primaryDomain: primaryDomain)
        case .mintingCompleted(let isPrimary):
            didFinishMinting(isPrimary: isPrimary)
        }
    }
}

// MARK: - CNavigationControllerDelegate
extension MintDomainsNavigationController: CNavigationControllerDelegate {
    func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool) {
        setSwipeGestureEnabledForCurrentState()
    }
}

// MARK: - Open methods
extension MintDomainsNavigationController {
    func setMode(_ mode: Mode) {
        switch mode {
        case .deepLink, .domainsPurchased:
            if topViewController is EnterEmailViewController {
                self.mode = mode
                setup()
            }
        case .default, .mintingInProgress:
            return
        }
    }
    
    func refreshMintingProgress() {
        guard let vc = self.topViewController as? TransactionInProgressViewController,
              let presenter = vc.presenter as? BaseTransactionInProgressViewPresenter else {
            return
        }
        
        presenter.refreshMintingTransactions()
    }
}

// MARK: - Private methods
private extension MintDomainsNavigationController {
    func moveToStep(_ step: Step) {
        guard let vc = createStep(step) else { return }
        
        self.pushViewController(vc, animated: true)
    }
    
    func didFinishMinting(isPrimary: Bool) {
        dismiss(result: .minted(isPrimary: isPrimary))
    }
    
    func isLastViewController(_ viewController: UIViewController) -> Bool {
        return viewController is EnterEmailViewController || viewController is WhatIsMintingViewController
    }
    
    func dismiss(result: Result) {
        if let vc = presentedViewController {
            vc.dismiss(animated: true)
        }
        cNavigationController?.transitionHandler?.isInteractionEnabled = true
        let domainsMintedCallback = self.domainsMintedCallback
        self.cNavigationController?.popViewController(animated: true) {
            domainsMintedCallback?(result)
        }
    }
    
    func setSwipeGestureEnabledForCurrentState() {
        guard let topViewController = viewControllers.last else { return }
        
        if topViewController is TransactionInProgressViewController {
            transitionHandler?.isInteractionEnabled = false
            cNavigationController?.transitionHandler?.isInteractionEnabled = false
        } else if topViewController is NoDomainsToMintViewController {
            transitionHandler?.isInteractionEnabled = false
            cNavigationController?.transitionHandler?.isInteractionEnabled = false
        } else {
            transitionHandler?.isInteractionEnabled = !isLastViewController(topViewController)
            cNavigationController?.transitionHandler?.isInteractionEnabled = isLastViewController(topViewController)
        }
    }
    
    func startMinting(domains: [String], primaryDomain: String?) async throws {
        guard let email = mintingData.email,
              let code = mintingData.code,
              let wallet = mintingData.wallet else {
            Debugger.printFailure("No wallet to mint", critical: true)
            return
        }
        
        let mintingDomains = try await dataAggregatorService.mintDomains(domains,
                                                                         paidDomains: [],
                                                                         newPrimaryDomain: primaryDomain,
                                                                         to: wallet,
                                                                         userEmail: email,
                                                                         securityCode: code)
        
        /// If user didn't set RR yet and mint multiple domains, ideally we would set RR automatically to domain user has selected as primary.
        /// Since it is impossible to ensure which domain will be set for RR, we will save user's primary domain selection and when minting is done, check if domain set for RR is same as primary. If they won't match, we'll ask if user want to set RR for primary domain just once.
        if domains.count > 1,
           await dataAggregatorService.reverseResolutionDomain(for: wallet) == nil,
            let primaryDomain = primaryDomain {
            UserDefaults.preferableDomainNameForRR = primaryDomain
        }
        
        if primaryDomain != nil {
            ConfettiImageView.prepareAnimationsAsync()
        }
        await MainActor.run {
            if primaryDomain != nil {
                moveToStep(.mintingInProgress(domains: mintingDomains))
            } else {
                didFinishMinting(isPrimary: false)
            }
        }
    }
}

// MARK: - Setup methods
private extension MintDomainsNavigationController {
    func setup() {
        isModalInPresentation = true
        setupBackButtonAlwaysVisible()
        
        switch mode {
        case .default:
            var initialViewController: UIViewController?
            if UserDefaults.shouldShowMintingTutorial,
               let vc = createStep(.whatIsMinting) {
                initialViewController = vc
            } else if let vc = createStep(.enterEmail(User.instance.email, shouldAutoSendEmail: false)) {
                initialViewController = vc
            }
            
            if let initialViewController {
                setViewControllers([initialViewController], animated: false)
            }
        case .domainsPurchased(let details):
            if let initialViewController = createStep(.enterEmail(details.email, shouldAutoSendEmail: true)) {
                User.instance.email = details.email
                mintingData.email = details.email
                setViewControllers([initialViewController], animated: false)
            }
        case .mintingInProgress(let domains):
            if let initialViewController = createStep(.mintingInProgress(domains: domains)) {
                setViewControllers([initialViewController], animated: false)
            }
        case .deepLink(let email, let code):
            if let initialViewController = createStep(.enterEmail(email, shouldAutoSendEmail: false)),
               let verificationViewController = createStep(.enterEmailVerificationCode(email: email, code: code)) {
                User.instance.email = email
                mintingData.email = email
                let emptyVC = BaseViewController()
                
                initialViewController.loadViewIfNeeded()
                initialViewController.viewWillAppear(false)
                setViewControllers([emptyVC, initialViewController, verificationViewController], animated: false)
                emptyVC.loadViewIfNeeded()
            }
        }
        setSwipeGestureEnabledForCurrentState()
    }
    
    func setupBackButtonAlwaysVisible() {
        navigationBar.alwaysShowBackButton = true
        navigationBar.setBackButton(hidden: false)
    }
    
    func createStep(_ step: Step) -> UIViewController? {
        switch step {
        case .whatIsMinting:
            let vc = WhatIsMintingViewController.nibInstance()
            let presenter = WhatIsMintingViewPresenter(view: vc,
                                                       mintDomainsFlowManager: self)
            vc.presenter = presenter
            
            return vc
        case .enterEmail(let preFilledEmail, let shouldAutoSendEmail):
            let vc = EnterEmailViewController.nibInstance()
            let presenter = EnterEmailToMintDomainsPresenter(view: vc,
                                                             userDataService: userDataService,
                                                             mintDomainsFlowManager: self,
                                                             preFilledEmail: preFilledEmail,
                                                             shouldAutoSendEmail: shouldAutoSendEmail)
            vc.presenter = presenter
            return vc
        case .enterEmailVerificationCode(let email, let code):
            let vc = EnterEmailVerificationCodeViewController.nibInstance()
            let presenter = EnterEmailVerificationCodeToMintDomainsPresenter(view: vc,
                                                                             email: email,
                                                                             preFilledCode: code,
                                                                             mintDomainsFlowManager: self,
                                                                             domainsService: domainsService,
                                                                             userDataService: userDataService,
                                                                             deepLinksService: appContext.deepLinksService)
            vc.presenter = presenter
            return vc
        case .noDomainsToMint(let email, let code):
            let vc = NoDomainsToMintViewController.nibInstance()
            let presenter = NoDomainsToMintViewPresenter(view: vc,
                                                         email: email,
                                                         code: code,
                                                         domainsService: domainsService,
                                                         mintDomainsFlowManager: self)
            vc.presenter = presenter
            return vc
        case .selectDomainsToMint(let unMintedDomains):
            let vc = MintDomainsConfigurationViewController.nibInstance()
            let presenter = MintDomainsConfigurationViewPresenter(view: vc,
                                                                  unMintedDomains: unMintedDomains,
                                                                  mintedDomains: mintedDomains,
                                                                  mintDomainsFlowManager: self,
                                                                  walletsService: walletsService)
            vc.presenter = presenter
            return vc
        case .choosePrimaryDomain(let domains, let primaryDomain):
            let vc = ChoosePrimaryDomainViewController.nibInstance()
            let presenter = ChoosePrimaryDomainDuringMintingPresenter(view: vc,
                                                                      mintDomainsFlowManager: self,
                                                                      domains: domains,
                                                                      primaryDomain: primaryDomain)
            vc.presenter = presenter
            return vc
        case .mintingInProgress(let domains):
            let vc = TransactionInProgressViewController.nibInstance()
            let presenter = MintingInProgressViewPresenter(view: vc,
                                                           mintingDomains: domains,
                                                           transactionsService: transactionsService,
                                                           mintDomainsFlowManager: self,
                                                           notificationsService: notificationsService)
            vc.presenter = presenter
            return vc
        }
    }
}

// MARK: - Private methods
private extension MintDomainsNavigationController {
    struct MintingData {
        var email: String? = nil
        var code: String? = nil
        var wallet: UDWallet? = nil
    }
}

extension MintDomainsNavigationController {
    enum Mode {
        case `default`
        case mintingInProgress(domains: [MintingDomain])
        case deepLink(email: String, code: String)
        case domainsPurchased(details: DomainsPurchasedDetails)
    }
    
    enum Step: Codable {
        case whatIsMinting
        case enterEmail(_ email: String?, shouldAutoSendEmail: Bool)
        case enterEmailVerificationCode(email: String, code: String?)
        case noDomainsToMint(email: String, code: String)
        case selectDomainsToMint(domains: [String])
        case choosePrimaryDomain(domains: [String], primaryDomain: DomainItem?)
        case mintingInProgress(domains: [MintingDomain])
    }
    
    enum Action {
        case getStartedAfterTutorial(shouldShowMintingTutorialInFuture: Bool)
        case sentCodeToEmail(_ email: String)
        case didReceiveUnMintedDomains(_ unMintedDomains: [String], email: String, code: String)
        case noDomainsGotItPressed
        case noDomainsImportWalletPressed
        case domainsPurchased(details: DomainsPurchasedDetails)
        case didSelectDomainsToMint(_ domains: [String], wallet: UDWallet)
        case didSelectDomainToMint(_ domain: String, wallet: UDWallet, isPrimary: Bool)
        case didConfirmDomainsToMint(_ domains: [String], primaryDomain: String?)
        case mintingCompleted(isPrimary: Bool)
    }
    
    enum Result {
        case cancel
        case noDomainsToMint
        case importWallet
        case minted(isPrimary: Bool)
        case domainsPurchased(details: DomainsPurchasedDetails)
    }
}

