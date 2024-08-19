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
    
}

