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

    var progress: Double? { 1 / 6 }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setDashesProgress(progress)
    }
}

// MARK: - Private methods
private extension PurchaseSearchDomainsViewController {
    func didScrollTo(offset: CGPoint) {
        cNavigationController?.underlyingScrollViewDidScrollTo(offset: offset)
    }
    
    func didSelectDomain(_ domain: DomainToPurchase) {
        Task {
            try? await purchaseDomainsFlowManager?.handle(action: .didSelectDomain(domain))
        }
    }
}

// MARK: - Setup methods
private extension PurchaseSearchDomainsViewController {
    func setup() {
        addProgressDashesView(configuration: .init(numberOfDashes: 3))
        addChildView()
    }
    
    func addChildView() {
        let vc = UIHostingController(rootView: PurchaseSearchDomainsView(domainSelectedCallback: { [weak self] domain in
            self?.didSelectDomain(domain)
        }, scrollOffsetCallback: { [weak self] offset in
            self?.didScrollTo(offset: offset)
        }))
        addChildViewController(vc, andEmbedToView: view)
    }
}
