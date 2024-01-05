//
//  ViewController.swift
//  manager
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import SwiftUI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showDomainsCollection()
    }
    
    @IBAction func runPurchaseButtonPressed() {
        UDRouter().showSearchDomainToPurchase(in: self) { result in
            
        }
    }
    
    func showPurchaseDomainsCheckout() {
        let view = PurchaseDomainsCheckoutView(domain: .init(name: "oleg.x", price: 10000, metadata: nil),
                                               selectedWallet: WalletWithInfo.mock[0],
                                               wallets: WalletWithInfo.mock,
                                               profileChanges: .init(domainName: "oleg.x"),
                                               delegate: nil)
        
        let vc = UIHostingController(rootView: view)
        addChildViewController(vc, andEmbedToView: self.view)
    }
    
    func showDomainsCollection() {
        let domainsCollectionVC = DomainsCollectionViewController.nibInstance()
        let presenter = PreviewDomainsCollectionViewPresenter(view: domainsCollectionVC)
        domainsCollectionVC.presenter = presenter
        let nav = CNavigationController(rootViewController: domainsCollectionVC)
        nav.modalTransitionStyle = .crossDissolve
        nav.modalPresentationStyle = .fullScreen
        
        present(nav, animated: false)
    }

    func showDomainProfile() {
        let domain = DomainToPurchase(name: "oleg.x", price: 10000, metadata: nil)
        let vc = DomainProfileViewController.nibInstance()
        let presenter = PurchaseDomainDomainProfileViewPresenter(view: vc,
                                                                 domain: domain)
        vc.presenter = presenter
        let nav = EmptyRootCNavigationController(rootViewController: vc)
        present(nav, animated: false)
    }
}

