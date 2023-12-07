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
    private var selectedWallet: WalletWithInfo!
    private var wallets: [WalletWithInfo]!
    private var isLoading = false
    override var analyticsName: Analytics.ViewName { .purchaseDomainsCheckout }
    
    var dashesProgressConfiguration: DashesProgressView.Configuration { .init(numberOfDashes: 3) }
    var progress: Double? { 5 / 6 }
    
    static func instantiate(domain: DomainToPurchase,
                            profileChanges: DomainProfilePendingChanges,
                            selectedWallet: WalletWithInfo,
                            wallets: [WalletWithInfo]) -> PurchaseDomainsCheckoutViewController {
        let vc = PurchaseDomainsCheckoutViewController()
        vc.domain = domain
        vc.profileChanges = profileChanges
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
