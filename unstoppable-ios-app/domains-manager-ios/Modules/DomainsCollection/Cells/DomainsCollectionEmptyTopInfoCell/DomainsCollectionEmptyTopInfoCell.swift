//
//  DomainsCollectionEmptyTopInfoCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.11.2022.
//

import UIKit

final class DomainsCollectionEmptyTopInfoCell: UICollectionViewCell {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isUserInteractionEnabled = false
        titleLabel.setTitle(String.Constants.domainsCollectionEmptyStateTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.domainsCollectionEmptyStateSubtitle.localized())
    }

}
