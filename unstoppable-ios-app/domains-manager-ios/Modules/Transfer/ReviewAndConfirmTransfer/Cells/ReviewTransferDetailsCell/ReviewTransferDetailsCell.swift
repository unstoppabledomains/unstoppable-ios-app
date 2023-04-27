//
//  ReviewTransferDetailsCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2023.
//

import UIKit

final class ReviewTransferDetailsCell: UICollectionViewCell {

    @IBOutlet private weak var domainTitleLabel: UILabel!
    @IBOutlet private weak var domainValueLabel: UILabel!
    @IBOutlet private weak var recipientTitleLabel: UILabel!
    @IBOutlet private weak var recipientValueLabel: UILabel!
    @IBOutlet private weak var chevronContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setTitle(String.Constants.domain.localized(), to: domainTitleLabel)
        setTitle(String.Constants.recipient.localized(), to: recipientTitleLabel)
        chevronContainerView.applyFigmaShadow(style: .small)
    }
    
}

// MARK: - Open methods
extension ReviewTransferDetailsCell {
    func setWith(configuration: ReviewAndConfirmTransferViewController.TransferDetailsConfiguration) {
        setValue(configuration.domain.name, to: domainValueLabel)
        setValue(configuration.recipient.visibleName, to: recipientValueLabel)
    }
}

// MARK: - Private methods
private extension ReviewTransferDetailsCell {
    func setTitle(_ title: String, to label: UILabel) {
        label.setAttributedTextWith(text: title,
                                    font: .currentFont(withSize: 14, weight: .regular),
                                    textColor: .foregroundSecondary,
                                    lineBreakMode: .byTruncatingTail)
    }
    
    func setValue(_ value: String, to label: UILabel) {
        let width = label.superview?.bounds.width ?? 0
        let font = UIFont.currentFont(withSize: 16, weight: .medium)
        label.setAttributedTextWith(text: value,
                                    font: font,
                                    textColor: .foregroundDefault,
                                    lineBreakMode: .byTruncatingTail)
        
        let requiredWidth = value.width(withConstrainedHeight: label.bounds.height, font: font)
        if requiredWidth > width {
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.85
        } else {
            label.adjustsFontSizeToFitWidth = false
        }
    }
}
