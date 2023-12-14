//
//  UDRouter+Common.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import UIKit

extension UDRouter {
    func showSearchDomainToPurchase(in viewController: UIViewController,
                                    domainsPurchasedCallback: @escaping  PurchaseDomainsNavigationController.DomainsPurchasedCallback) {
        let purchaseDomainsNavigationController = PurchaseDomainsNavigationController()
        purchaseDomainsNavigationController.domainsPurchasedCallback = domainsPurchasedCallback
        viewController.cNavigationController?.pushViewController(purchaseDomainsNavigationController,
                                                                 animated: true)
    }
}
