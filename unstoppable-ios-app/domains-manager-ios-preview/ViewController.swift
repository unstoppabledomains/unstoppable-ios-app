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
        print("Did load")
//        showDomainsCollection()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Did appear")
        showDomainProfile()
    }
    
    func showPurchaseDomainsCheckout() {
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
        let wallet = UDWallet.mock[0]
        let walletInfo = WalletDisplayInfo(wallet: wallet, domainsCount: 1, udDomainsCount: 1)!
        let domain = DomainDisplayInfo(name: "oleg.x", ownerWallet: wallet.address, isSetForRR: false)
        let preRequestedAction: PreRequestedProfileAction? = nil
        let sourceScreen = DomainProfileViewPresenter.SourceScreen.domainsCollection
        let vc = DomainProfileViewController.nibInstance()
        let presenter = DomainProfileViewPresenter(view: vc,
                                                   domain: domain,
                                                   wallet: wallet,
                                                   walletInfo: walletInfo,
                                                   preRequestedAction: preRequestedAction,
                                                   sourceScreen: sourceScreen,
                                                   dataAggregatorService: appContext.dataAggregatorService,
                                                   domainRecordsService: appContext.domainRecordsService,
                                                   domainTransactionsService: appContext.domainTransactionsService,
                                                   coinRecordsService: appContext.coinRecordsService,
                                                   externalEventsService: appContext.externalEventsService)
        vc.presenter = presenter
        let nav = CNavigationController(rootViewController: vc)
        present(nav, animated: false)
    }
}

