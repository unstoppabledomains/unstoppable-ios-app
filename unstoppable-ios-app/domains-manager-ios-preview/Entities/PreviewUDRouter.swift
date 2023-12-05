//
//  PreviewUDRouter.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import UIKit

final class UDRouter {
    func showWalletDetailsOf(wallet: UDWallet,
                             walletInfo: WalletDisplayInfo,
                             source: WalletDetailsSource,
                             in viewController: CNavigationController) { }
    func showSetupChangeReverseResolutionModule(in viewController: UIViewController,
                                                wallet: UDWallet,
                                                walletInfo: WalletDisplayInfo,
                                                domain: DomainDisplayInfo,
                                                resultCallback: @escaping EmptyAsyncCallback) { }
}



extension UDRouter {
    enum WalletDetailsSource {
        case walletsList
        case domainDetails
        case domainsCollection
    }
    
    enum UDRouterError: Error {
        case dismissed
    }
}
