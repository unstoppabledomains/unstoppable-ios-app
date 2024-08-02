//
//  PurchaseDomainsCheckoutViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.11.2023.
//

import SwiftUI

final class PurchaseDomainsCheckoutViewController: BaseViewController, ViewWithDashesProgress, UDNavigationBackButtonHandler {
    
    override var scrollableContentYOffset: CGFloat? { 16 }
    
    weak var purchaseDomainsFlowManager: PurchaseDomainsFlowManager?
    private var domain: DomainToPurchase!
    private var profileChanges: DomainProfilePendingChanges!
    private var selectedWallet: WalletEntity!
    private var wallets: [WalletEntity]!
    private var isLoading = false
    override var analyticsName: Analytics.ViewName { .purchaseDomainsCheckout }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }

    var dashesProgressConfiguration: DashesProgressView.Configuration { .init(numberOfDashes: 3) }
    var progress: Double? { 5 / 6 }
    override var additionalAppearAnalyticParameters: Analytics.EventParameters { [.domainName : domain.name,
                                                                                  .price: String(domain.price)] }
    
    static func instantiate(domains: [DomainToPurchase],
                            profileChanges: DomainProfilePendingChanges?,
                            selectedWallet: WalletEntity,
                            wallets: [WalletEntity]) -> PurchaseDomainsCheckoutViewController {
        let vc = PurchaseDomainsCheckoutViewController()
        vc.domain = domains[0]
        vc.profileChanges = profileChanges ?? .init(domainName: domains[0].name)
        vc.selectedWallet = selectedWallet
        vc.wallets = wallets
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func shouldPopOnBackButton() -> Bool {
        guard !isLoading else { return false }
        
        Task { await appContext.purchaseDomainsService.reset() }
        return true
    }
}

// MARK: - PurchaseDomainsCheckoutViewDelegate
extension PurchaseDomainsCheckoutViewController: PurchaseDomainsCheckoutViewDelegate {
    func purchaseViewDidPurchaseDomains() {
        Task { @MainActor in
            try? await purchaseDomainsFlowManager?.handle(action: .didPurchaseDomains)
        }
    }
    
    func purchaseViewDidUpdateScrollOffset(_ scrollOffset: CGPoint) {
        cNavigationController?.underlyingScrollViewDidScrollTo(offset: scrollOffset)
    }
    
    func purchaseViewDidUpdateLoadingState(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}

// MARK: - Setup methods
private extension PurchaseDomainsCheckoutViewController {
    func setup() {
        addProgressDashesView(configuration: .init(numberOfDashes: 3))
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let view = PurchaseDomainsCheckoutView(domain: domain,
                                               selectedWallet: selectedWallet,
                                               wallets: wallets,
                                               profileChanges: profileChanges,
                                               delegate: self)
        
        let vc = UIHostingController(rootView: view)
        addChildViewController(vc, andEmbedToView: self.view)
    }
}
