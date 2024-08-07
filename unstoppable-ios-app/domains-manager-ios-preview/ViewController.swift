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
        
    }
    
    @IBAction func runPurchaseButtonPressed() {
       
    }
    
    func showPurchaseDomainsSearch() {
        let view = PurchaseDomainsSearchView()
        
        let vc = UIHostingController(rootView: view)
        addChildViewController(vc, andEmbedToView: self.view)
    }
    
    func showPurchaseDomainsCheckout() {
        let view = PurchaseDomainsCheckoutView(domain: .init(name: "oleg.x", price: 10000, metadata: nil, isAbleToPurchase: true),
                                               selectedWallet: MockEntitiesFabric.Wallet.mockEntities()[0],
                                               wallets: MockEntitiesFabric.Wallet.mockEntities(),
                                               profileChanges: .init(domainName: "oleg.x"))
        
        let vc = UIHostingController(rootView: view)
        addChildViewController(vc, andEmbedToView: self.view)
    }

}

