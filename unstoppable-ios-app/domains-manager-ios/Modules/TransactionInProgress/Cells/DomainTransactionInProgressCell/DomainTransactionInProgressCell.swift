//
//  DomainTransactionInProgressCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2023.
//

import UIKit

final class DomainTransactionInProgressCell: UICollectionViewCell {

    @IBOutlet private weak var domainCardView: UDDomainSharingCardView!

}

// MARK: - Open methods
extension DomainTransactionInProgressCell {
    func setWith(domain: DomainDisplayInfo) {
        domainCardView.setWith(domain: domain, qrImage: nil)
    }
}
