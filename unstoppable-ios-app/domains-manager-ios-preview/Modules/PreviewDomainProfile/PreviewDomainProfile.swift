//
//  PreviewDomainProfile.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import SwiftUI


@available(iOS 17, *)
#Preview {
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
    
    return nav
}

