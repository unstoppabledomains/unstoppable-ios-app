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
        
        let view = PurchaseDomainsCheckoutView(domain: .init(name: "oleg.x", price: 10000, metadata: nil),
                                               selectedWallet: WalletWithInfo.mock[0],
                                               wallets: WalletWithInfo.mock,
                                               purchasedCallback: { [weak self] in
            
        },
                                               scrollOffsetCallback: { [weak self] offset in
            
        })
        
        let vc = UIHostingController(rootView: view)
        addChildViewController(vc, andEmbedToView: self.view)
    }


}

