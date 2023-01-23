//
//  DomainsCollectionMintingInProgressCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.05.2022.
//

import UIKit

final class DomainsCollectionMintingInProgressCell: BaseListCollectionViewCell {

    @IBOutlet private weak var refreshIconView: KeepingAnimationImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var domainsCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
        titleLabel.setAttributedTextWith(text: String.Constants.mintingInProgressTitle.localized(),
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .foregroundAccent)
        refreshIconView.runUpdatingRecordsAnimation()
    }
}

// MARK: - Open methods
extension DomainsCollectionMintingInProgressCell {
    func setWith(domainsCount: Int) {
        domainsCountLabel.setAttributedTextWith(text: String.Constants.pluralNDomains.localized(domainsCount, domainsCount),
                                                font: .currentFont(withSize: 14, weight: .regular),
                                                textColor: .foregroundSecondary)
        refreshIconView.runUpdatingRecordsAnimation()
    }
}
