//
//  PurchaseDomainsNavigationController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import UIKit

@MainActor
protocol PurchaseDomainsFlowManager: AnyObject {
    func handle(action: PurchaseDomainsNavigationController.Action) async throws
}

final class PurchaseDomainsNavigationController: CNavigationController {
    
    typealias DomainsPurchasedCallback = ((Result)->())
    typealias PurchaseDomainsResult = Result
    
    private var mode: Mode = .default
    private var purchaseData: PurchaseData = PurchaseData()
    var domainsPurchasedCallback: DomainsPurchasedCallback?

    convenience init(mode: Mode = .default) {
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
        
        if isLastViewController(topViewController) {
            return cNavigationController?.popViewController(animated: true)
        }
        return super.popViewController(animated: animated, completion: completion)
    }
}

// MARK: - PurchaseDomainsFlowManager
extension PurchaseDomainsNavigationController: PurchaseDomainsFlowManager {
    func handle(action: Action) async throws {
        switch action {
        case .didSelectDomain(let domain):
            purchaseData.domain = domain
            let wallets = await appContext.dataAggregatorService.getWalletsWithInfo()
            guard let selectedWallet = wallets.first else { return }
            
            moveToStep(.checkout(domain: domain,
                                 selectedWallet: selectedWallet,
                                 wallets: wallets))
        case .didPurchaseDomains:
            moveToStep(.purchased)
        case .goToDomains:
            didFinishPurchase()
        }
    }
}

// MARK: - CNavigationControllerDelegate
extension PurchaseDomainsNavigationController: CNavigationControllerDelegate {
    func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool) {
        setSwipeGestureEnabledForCurrentState()
    }
}

// MARK: - Private methods
private extension PurchaseDomainsNavigationController {
    func moveToStep(_ step: Step) {
        guard let vc = createStep(step) else { return }
        
        self.pushViewController(vc, animated: true)
    }
    
    func didFinishPurchase() {
        dismiss(result: .purchased)
    }
    
    func isLastViewController(_ viewController: UIViewController) -> Bool {
        viewController is PurchaseSearchDomainsViewController
    }
    
    func dismiss(result: Result) {
        if let vc = presentedViewController {
            vc.dismiss(animated: true)
        }
        cNavigationController?.transitionHandler?.isInteractionEnabled = true
        let domainsPurchasedCallback = self.domainsPurchasedCallback
        self.cNavigationController?.popViewController(animated: true) {
            domainsPurchasedCallback?(result)
        }
    }
    
    func setSwipeGestureEnabledForCurrentState() {
        guard let topViewController = viewControllers.last else { return }
        
        if topViewController is HappyEndViewController {
            transitionHandler?.isInteractionEnabled = false
            cNavigationController?.transitionHandler?.isInteractionEnabled = false
        } else {
            transitionHandler?.isInteractionEnabled = !isLastViewController(topViewController)
            cNavigationController?.transitionHandler?.isInteractionEnabled = isLastViewController(topViewController)
        }
    }
    
    func purchase(domains: [DomainToPurchase], domainsOrderInfoMap: SortDomainsOrderInfoMap?) async throws {
        
    }
    
    func createDomainsOrderInfoMap(for domains: [String]) -> SortDomainsOrderInfoMap {
        var map = SortDomainsOrderInfoMap()
        for (i, domain) in domains.enumerated() {
            map[domain] = i
        }
        return map
    }
}

// MARK: - Setup methods
private extension PurchaseDomainsNavigationController {
    func setup() {
        isModalInPresentation = true
        setupBackButtonAlwaysVisible()
        
        switch mode {
        case .default:
            if let initialViewController = createStep(.searchDomain) {
                setViewControllers([initialViewController], animated: false)
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
        case .searchDomain:
            let vc = PurchaseSearchDomainsViewController()
            vc.purchaseDomainsFlowManager = self
            return vc
        case .checkout(let domain, let selectedWallet, let wallets):
            let vc = PurchaseDomainsCheckoutViewController.instantiate(domain: domain,
                                                                       selectedWallet: selectedWallet,
                                                                       wallets: wallets)
            vc.purchaseDomainsFlowManager = self
            return vc
        case .purchased:
            let vc = HappyEndViewController.instance()
            let presenter = PurchaseDomainsHappyEndViewPresenter(view: vc)
            presenter.purchaseDomainsFlowManager = self
            vc.presenter = presenter
            return vc
        }
    }
}

// MARK: - Private methods
private extension PurchaseDomainsNavigationController {
    struct PurchaseData {
        var domain: DomainToPurchase?
        var wallet: UDWallet? = nil
    }
}

extension PurchaseDomainsNavigationController {
    enum Mode {
        case `default`
    }
    
    enum Step {
        case searchDomain
        case checkout(domain: DomainToPurchase, selectedWallet: WalletWithInfo, wallets: [WalletWithInfo])
        case purchased
    }
    
    enum Action {
        case didSelectDomain(_ domain: DomainToPurchase)
        case didPurchaseDomains
        case goToDomains
    }
    
    enum Result {
        case cancel
        case purchased
    }
}
