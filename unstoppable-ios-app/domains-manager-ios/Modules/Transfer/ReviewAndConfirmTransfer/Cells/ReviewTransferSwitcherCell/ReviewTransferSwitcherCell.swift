//
//  ReviewTransferSwitcherCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2023.
//

import UIKit

final class ReviewTransferSwitcherCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var switcher: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

// MARK: - Open methods
extension ReviewTransferSwitcherCell {
    func setWith(configuration: ReviewAndConfirmTransferViewController.TransferSwitcherConfiguration) {
        switcher.isOn = configuration.isOn
        
        let title = configuration.type.title
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .foregroundDefault,
                                         lineHeight: 24)
        
        let subtitle = configuration.type.subtitle
        subtitleLabel.setAttributedTextWith(text: subtitle ?? "",
                                         font: .currentFont(withSize: 14, weight: .regular),
                                         textColor: .foregroundSecondary)
        subtitleLabel.isHidden = subtitle == nil
    }
}

// MARK: - Actions
private extension ReviewTransferSwitcherCell {
    @IBAction func switchValueChanged(_ sender: Any) {
        
    }
}
