//
//  DomainProfileNoSocialsCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.11.2022.
//

import UIKit

final class DomainProfileNoSocialsCell: UICollectionViewCell {

    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        titleLabel.setAttributedTextWith(text: String.Constants.comingSoon.localized(),
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .white.withAlphaComponent(0.56))
        subtitleLabel.setAttributedTextWith(text: String.Constants.profileSocialsEmptyMessage.localized(),
                                         font: .currentFont(withSize: 14, weight: .regular),
                                         textColor: .white.withAlphaComponent(0.32),
                                         lineHeight: 20)
    }

}
