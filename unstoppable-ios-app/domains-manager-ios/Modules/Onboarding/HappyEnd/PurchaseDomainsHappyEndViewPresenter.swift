//
//  PurchaseDomainsHappyEndViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2023.
//

import Foundation

final class PurchaseDomainsHappyEndViewPresenter: BaseHappyEndViewPresenter {
    
    override var analyticsName: Analytics.ViewName { .domainsPurchasedHappyEnd }
    
    weak var purchaseDomainsFlowManager: PurchaseDomainsFlowManager?
    weak var purchaseDomainsViewModel: PurchaseDomainsViewModel?

    override func viewDidLoad() {
        view?.setAgreement(visible: false)
        view?.setConfiguration(.domainsPurchased)
    }
    
    override func actionButtonPressed() {
        Task {
            try? await purchaseDomainsFlowManager?.handle(action: .goToDomains)
            purchaseDomainsViewModel?.handleAction(.goToDomains)
        }
    }
}
