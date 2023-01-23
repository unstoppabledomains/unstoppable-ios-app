//
//  SecuritySettingsAuthSelectionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import UIKit

final class SecuritySettingsAuthSelectionCell: BaseListCollectionViewCell {

    @IBOutlet private weak var imageContainerView: ResizableRoundedImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var onIndicatorView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageContainerView.setSize(.init(containerSize: 40, imageSize: 20))
        imageContainerView.setStyle(.imageCentered)
        imageContainerView.tintColor = .foregroundDefault
    }

    func setWith(authType: SecuritySettingsViewController.AuthenticationType) {
        imageContainerView.image = authType.icon
        nameLabel.setAttributedTextWith(text: authType.title,
                                        font: .currentFont(withSize: 16,
                                                           weight: .medium),
                                        textColor: .foregroundDefault)
        switch authType {
        case .biometric(let isOn), .passcode(let isOn):
            onIndicatorView.isHidden = !isOn
        }
    }
}

