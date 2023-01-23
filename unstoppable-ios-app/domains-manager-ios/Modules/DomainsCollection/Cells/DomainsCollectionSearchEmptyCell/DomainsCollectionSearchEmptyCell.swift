//
//  DomainsCollectionSearchEmptyCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.07.2022.
//

import UIKit

final class DomainsCollectionSearchEmptyCell: UICollectionViewCell {

    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var centerYConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        isUserInteractionEnabled = false
        titleLabel.setAttributedTextWith(text: String.Constants.searchDomainsTitle.localized(),
                                         font: .currentFont(withSize: 22, weight: .bold),
                                         textColor: .foregroundSecondary)
        hintLabel.setAttributedTextWith(text: String.Constants.searchDomainsHint.localized(),
                                        font: .currentFont(withSize: 16, weight: .regular),
                                        textColor: .foregroundSecondary)
    }

}

// MARK: - Open methods
extension DomainsCollectionSearchEmptyCell {
    func setCenterYOffset(_ offset: CGFloat) {
        centerYConstraint.constant = offset
    }
}
