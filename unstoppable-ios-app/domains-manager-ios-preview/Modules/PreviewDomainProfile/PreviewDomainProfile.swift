//
//  PreviewDomainProfile.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import SwiftUI


@available(iOS 17, *)
#Preview {
    let domain = DomainToPurchase(name: "oleg.x", price: 10000, metadata: nil)
    let vc = DomainProfileViewController.nibInstance()
    let presenter = PurchaseDomainDomainProfileViewPresenter(view: vc,
                                               domain: domain)
    vc.presenter = presenter
    let nav = EmptyRootCNavigationController(rootViewController: vc)
    
    return nav
}

