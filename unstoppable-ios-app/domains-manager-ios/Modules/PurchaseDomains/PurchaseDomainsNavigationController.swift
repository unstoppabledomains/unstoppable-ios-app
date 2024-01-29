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
            if let navigationController {
                return navigationController.popViewController(animated: true)
            }
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
            moveToStep(.fillProfile(domain: domain))
        case .didFillProfileForDomain(let domain, let profileChanges):
            moveToCheckoutWith(domain: domain,
                               profileChanges: profileChanges)
        case .didPurchaseDomains:
            Task {
                try? await Task.sleep(seconds: 0.5)
                await appContext.purchaseDomainsService.reset()
            }
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
        dismiss(result: .purchased(domainName: purchaseData.domain?.name ?? ""))
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
        navigationController?.popViewController(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            domainsPurchasedCallback?(result)
        }
    }
    
    func setSwipeGestureEnabledForCurrentState() {        
        transitionHandler?.isInteractionEnabled = false
        cNavigationController?.transitionHandler?.isInteractionEnabled = false
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
    
    func moveToCheckoutWith(domain: DomainToPurchase,
                            profileChanges: DomainProfilePendingChanges) {
        Task { @MainActor in
            let wallets = await appContext.dataAggregatorService.getWalletsWithInfo()
            guard let selectedWallet = wallets.first else {
                askUserToAddWalletToPurchase(domain: domain,
                                             profileChanges: profileChanges)
                return
            }
            
            purchaseData.domain = domain
            moveToStep(.checkout(domain: domain,
                                 profileChanges: profileChanges,
                                 selectedWallet: selectedWallet,
                                 wallets: wallets))
        }
    }
    
    func askUserToAddWalletToPurchase(domain: DomainToPurchase,
                                      profileChanges: DomainProfilePendingChanges) {
        Task {
            do {
                let action = try await appContext.pullUpViewService.showAddWalletSelectionPullUp(in: self,
                                                                                                 presentationOptions: .addToPurchase,
                                                                                                 actions: WalletDetailsAddWalletAction.allCases)
                await dismissPullUpMenu()
                
                UDRouter().showAddWalletScreenForAction(action,
                                                        in: self,
                                                        addedCallback: { [weak self] result in
                    switch result {
                    case .created, .createdAndBackedUp:
                        self?.moveToCheckoutWith(domain: domain,
                                                 profileChanges: profileChanges)
                    case .cancelled, .failedToAdd:
                        return
                    }
                })
            }
        }
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
        case .fillProfile(let domain):
            let vc = DomainProfileViewController.nibInstance()
            let presenter = PurchaseDomainDomainProfileViewPresenter(view: vc,
                                                                     domain: domain)
            presenter.purchaseDomainsFlowManager = self
            vc.presenter = presenter
            return vc
        case .checkout(let domain, let profileChanges, let selectedWallet, let wallets):
            let vc = PurchaseDomainsCheckoutViewController.instantiate(domain: domain,
                                                                       profileChanges: profileChanges,
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
        case fillProfile(domain: DomainToPurchase)
        case checkout(domain: DomainToPurchase, profileChanges: DomainProfilePendingChanges, selectedWallet: WalletWithInfo, wallets: [WalletWithInfo])
        case purchased
    }
    
    enum Action {
        case didSelectDomain(_ domain: DomainToPurchase)
        case didFillProfileForDomain(_ domain: DomainToPurchase, profileChanges: DomainProfilePendingChanges)
        case didPurchaseDomains
        case goToDomains
    }
    
    enum Result {
        case cancel
        case purchased(domainName: String)
    }
}

import SwiftUI
struct PurchaseDomainsNavigationControllerWrapper: UIViewControllerRepresentable {
    
    let domainsPurchasedCallback:  PurchaseDomainsNavigationController.DomainsPurchasedCallback
    
    func makeUIViewController(context: Context) -> UIViewController {
        let purchaseDomainsNavigationController = PurchaseDomainsNavigationController()
        purchaseDomainsNavigationController.domainsPurchasedCallback = domainsPurchasedCallback
        return purchaseDomainsNavigationController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
}
