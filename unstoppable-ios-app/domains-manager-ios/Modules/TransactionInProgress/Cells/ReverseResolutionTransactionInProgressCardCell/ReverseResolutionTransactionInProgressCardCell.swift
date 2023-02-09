//
//  ReverseResolutionTransactionInProgressCardCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.09.2022.
//

import UIKit

final class ReverseResolutionTransactionInProgressCardCell: UICollectionViewCell {

    @IBOutlet private weak var domainCardView: UDDomainCardView!
    @IBOutlet private weak var walletInfoBadgeView: WalletInfoBadgeView!

}

// MARK: - Open methods
extension ReverseResolutionTransactionInProgressCardCell {
    func setWith(domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo) {
        domainCardView.setWith(domainItem: domain)
        walletInfoBadgeView.setWith(walletInfo: walletInfo)
    }
}
