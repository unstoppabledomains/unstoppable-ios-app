//
//  PurchaseSearchDomainsViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import SwiftUI

final class PurchaseSearchDomainsViewController: BaseViewController, ViewWithDashesProgress {
    
    override var scrollableContentYOffset: CGFloat? { 16 }

    weak var purchaseDomainsFlowManager: PurchaseDomainsFlowManager?
    override var analyticsName: Analytics.ViewName { .purchaseDomainsSearch }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }

    var dashesProgressConfiguration: DashesProgressView.Configuration { .init(numberOfDashes: 3) }
    var progress: Double? { 1 / 6 }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Private methods
private extension PurchaseSearchDomainsViewController {
    func didScrollTo(offset: CGPoint) {
        cNavigationController?.underlyingScrollViewDidScrollTo(offset: offset)
    }
    
    func didSelectDomains(_ domains: [DomainToPurchase]) {
        Task {
            try? await purchaseDomainsFlowManager?.handle(action: .didSelectDomains(domains))
        }
    }
}

// MARK: - Setup methods
private extension PurchaseSearchDomainsViewController {
    func setup() {
        addProgressDashesView(configuration: .init(numberOfDashes: 3))
        addChildView()
        DispatchQueue.main.async {
            self.setDashesProgress(self.progress)
        }
    }
    
    func addChildView() {
        let vc = UIHostingController(rootView: PurchaseSearchDomainsView(domainSelectedCallback: { [weak self] domains in
            self?.didSelectDomains(domains)
        }, scrollOffsetCallback: { [weak self] offset in
            self?.didScrollTo(offset: offset)
        }))
        addChildViewController(vc, andEmbedToView: view)
    }
}
