//
//  PurchaseDomainsCheckoutViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.11.2023.
//

import SwiftUI

final class PurchaseDomainsCheckoutViewController: BaseViewController, ViewWithDashesProgress {
    
    override var scrollableContentYOffset: CGFloat? { 16 }
    
    weak var purchaseDomainsFlowManager: PurchaseDomainsFlowManager?
    private var domain: DomainToPurchase!
    private var selectedWallet: WalletWithInfo!
    private var wallets: [WalletWithInfo]!
    
    var progress: Double? { 5 / 6 }
    
    static func instantiate(domain: DomainToPurchase,
                            selectedWallet: WalletWithInfo,
                            wallets: [WalletWithInfo]) -> PurchaseDomainsCheckoutViewController {
        let vc = PurchaseDomainsCheckoutViewController()
        vc.domain = domain
        vc.selectedWallet = selectedWallet
        vc.wallets = wallets
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension PurchaseDomainsCheckoutViewController {
    func didScrollTo(offset: CGPoint) {
        cNavigationController?.underlyingScrollViewDidScrollTo(offset: offset)
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
                                               purchasedCallback: {
            
        },
                                               scrollOffsetCallback: { [weak self] offset in
            self?.didScrollTo(offset: offset)
        })
        
        let vc = UIHostingController(rootView: view)
        addChildViewController(vc, andEmbedToView: self.view)
    }
}
