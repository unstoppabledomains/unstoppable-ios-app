//
//  WalletsEmptyStateCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import UIKit

final class WalletsEmptyStateCell: UICollectionViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.setAttributedTextWith(text: String.Constants.walletsListEmptyTitle.localized(),
                                         font: .currentFont(withSize: 22, weight: .bold),
                                         textColor: .foregroundSecondary)
        subtitleLabel.setAttributedTextWith(text: String.Constants.walletsListEmptySubtitle.localized(),
                                            font: .currentFont(withSize: 16, weight: .regular),
                                            textColor: .foregroundSecondary)
    }
    
}
