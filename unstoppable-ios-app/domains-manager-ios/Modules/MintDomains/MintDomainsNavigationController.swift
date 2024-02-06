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
    
    typealias DomainsMintedCallback = ((MintDomainsResult)->())

    private var mintedDomains: [DomainDisplayInfo] = []
    private var mode: Mode = .default(email: User.instance.email)
    private var mintingData: MintingData = MintingData()
    
    private let dataAggregatorService: DataAggregatorServiceProtocol = appContext.dataAggregatorService
    private let userDataService: UserDataServiceProtocol = appContext.userDataService
    private let domainsService: UDDomainsServiceProtocol = appContext.udDomainsService
    private let walletsService: UDWalletsServiceProtocol = appContext.udWalletsService
    private let transactionsService: DomainTransactionsServiceProtocol = appContext.domainTransactionsService
    private let notificationsService: NotificationsServiceProtocol = appContext.notificationsService

    var domainsMintedCallback: DomainsMintedCallback?

    convenience init(mode: Mode, mintedDomains: [DomainDisplayInfo]) {
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
        
        if isLastViewController(topViewController) {
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
            Debugger.printFailure("should not get here")
//            self.mintingData.wallet = wallet
//            if domains.count == 1 {
//                if mintedDomains.isEmpty {
//                    try await startMinting(domains: domains, domainsOrderInfoMap: nil)
//                } else {
//                    moveToStep(.choosePrimaryDomain(domains: domains))
//                }
//            } else {
//                moveToStep(.choosePrimaryDomain(domains: domains))
//            }
        case .didConfirmDomainsToMint(let domains, let domainsOrderInfoMap):
            Debugger.printFailure("should not get here")
//            try await startMinting(domains: domains, domainsOrderInfoMap: domainsOrderInfoMap)
        case .mintingCompleted:
            didFinishMinting()
        case .skipMinting:
            didSkipMinting()
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
    
    func didFinishMinting() {
        dismiss(result: .minted)
    }
    
    func didSkipMinting() {
        dismiss(result: .skipped)
    }
    
    func isLastViewController(_ viewController: UIViewController) -> Bool {
        viewController is EnterEmailViewController ||
        viewController is TransactionInProgressViewController
    }
    
    func dismiss(result: MintDomainsResult) {
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
        
        if topViewController is NoDomainsToMintViewController {
            transitionHandler?.isInteractionEnabled = false
            cNavigationController?.transitionHandler?.isInteractionEnabled = false
        } else {
            transitionHandler?.isInteractionEnabled = !isLastViewController(topViewController)
            cNavigationController?.transitionHandler?.isInteractionEnabled = isLastViewController(topViewController)
        }
    }
    
//    func startMinting(domains: [String], domainsOrderInfoMap: SortDomainsOrderInfoMap?) async throws {
//        guard let email = mintingData.email,
//              let code = mintingData.code,
//              let wallet = mintingData.wallet else {
//            Debugger.printFailure("No wallet to mint", critical: true)
//            return
//        }
//        
//        let domainsOrderInfoMap = domainsOrderInfoMap ?? createDomainsOrderInfoMap(for: domains)
//        let mintingDomains = try await dataAggregatorService.mintDomains(domains,
//                                                                         paidDomains: [],
//                                                                         domainsOrderInfoMap: domainsOrderInfoMap,
//                                                                         to: wallet,
//                                                                         userEmail: email,
//                                                                         securityCode: code)
//        
//        /// If user didn't set RR yet and mint multiple domains, ideally we would set RR automatically to domain user has selected as primary.
//        /// Since it is impossible to ensure which domain will be set for RR, we will save user's primary domain selection and when minting is done, check if domain set for RR is same as primary. If they won't match, we'll ask if user want to set RR for primary domain just once.
//        if let primaryDomainName = domainsOrderInfoMap.first(where: { $0.value == 0 })?.key,
//           domains.contains(primaryDomainName),
//           await dataAggregatorService.reverseResolutionDomain(for: wallet) == nil {
//            UserDefaults.preferableDomainNameForRR = primaryDomainName
//        } else if mintedDomains.filter({ wallet.owns(domain: $0) }).isEmpty {
//            /// Transferring first domain to the wallet. Before RR was set automatically, with new system it is not.
//            UserDefaults.preferableDomainNameForRR = domains.first
//        }
//   
//        await MainActor.run {
//            if domains.count > 1 {
//                didSkipMinting()
//            } else {
//                moveToStep(.mintingInProgress(domains: mintingDomains))
//            }
//        }
//    }
    
    func createDomainsOrderInfoMap(for domains: [String]) -> SortDomainsOrderInfoMap {
        var map = SortDomainsOrderInfoMap()
        for (i, domain) in domains.enumerated() {
            map[domain] = i
        }
        return map
    }
}

// MARK: - Setup methods
private extension MintDomainsNavigationController {
    func setup() {
        isModalInPresentation = true
        setupBackButtonAlwaysVisible()
        
        switch mode {
        case .default(let email):
            if let initialViewController = createStep(.enterEmail(email, shouldAutoSendEmail: false)) {
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
        case .choosePrimaryDomain(let domains):
            let vc = ChoosePrimaryDomainViewController.nibInstance()
            let presenter = ChoosePrimaryDomainDuringMintingPresenter(view: vc,
                                                                      mintDomainsFlowManager: self,
                                                                      domainsToMint: domains,
                                                                      mintedDomains: self.mintedDomains)
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
        case `default`(email: String?)
        case mintingInProgress(domains: [MintingDomain])
        case deepLink(email: String, code: String)
        case domainsPurchased(details: DomainsPurchasedDetails)
    }
    
    enum Step: Codable {
        case enterEmail(_ email: String?, shouldAutoSendEmail: Bool)
        case enterEmailVerificationCode(email: String, code: String?)
        case noDomainsToMint(email: String, code: String)
        case selectDomainsToMint(domains: [String])
        case choosePrimaryDomain(domains: [String])
        case mintingInProgress(domains: [MintingDomain])
    }
    
    enum Action {
        case sentCodeToEmail(_ email: String)
        case didReceiveUnMintedDomains(_ unMintedDomains: [String], email: String, code: String)
        case noDomainsGotItPressed
        case noDomainsImportWalletPressed
        case domainsPurchased(details: DomainsPurchasedDetails)
        case didSelectDomainsToMint(_ domains: [String], wallet: UDWallet)
        case didConfirmDomainsToMint(_ domains: [String], domainsOrderInfoMap: SortDomainsOrderInfoMap)
        case mintingCompleted
        case skipMinting
    }
}

