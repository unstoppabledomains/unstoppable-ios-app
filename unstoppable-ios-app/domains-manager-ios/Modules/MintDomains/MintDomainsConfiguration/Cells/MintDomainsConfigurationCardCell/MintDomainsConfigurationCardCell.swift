//
//  MintDomainsConfigurationCardCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

final class MintDomainsConfigurationCardCell: UICollectionViewCell {

    @IBOutlet private weak var domainCardView: UDDomainCardView!
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cardViewWidthConstraint: NSLayoutConstraint!
    
}

// MARK: - Open methods
extension MintDomainsConfigurationCardCell {
    func setWith(domain: String, height: CGFloat = 382, shouldAdjustCardWidth: Bool = false) {
        domainCardView.setWith(domainName: domain, avatarImage: nil)
        heightConstraint.constant = height
        if shouldAdjustCardWidth {
            if deviceSize == .i4Inch {
                cardViewWidthConstraint.constant = 216
            }
        }
    }
}
