//
//  PurchaseDomainProfileTopInfoCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import UIKit

final class PurchaseDomainProfileTopInfoCell: BaseDomainProfileTopInfoCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var addAvatarButton: SmallRaisedTertiaryWhiteButton!
    @IBOutlet private weak var addCoverButton: SmallRaisedTertiaryWhiteButton!

    override var minBannerOffset: CGFloat { 0 }
    override var avatarPlaceholder: UIImage? { .domainSharePlaceholder }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.setAttributedTextWith(text: "Create your profile",
                                         font: .currentFont(withSize: 32, weight: .bold),
                                         textColor: .foregroundOnEmphasis)
        messageLabel.setAttributedTextWith(text: "All fields are optional",
                                           font: .currentFont(withSize: 14, weight: .medium),
                                           textColor: .white.withAlphaComponent(0.56))
        addAvatarButton.setTitle("Add avatar", image: .avatarsIcon16)
        addCoverButton.setTitle("Add cover", image: .framesIcon16)

    }

    override func set(with data: DomainProfileViewController.ItemTopInfoData) {
        super.set(with: data)
        
        domainNameLabel.setAttributedTextWith(text: data.domain.name,
                                              font: .currentFont(withSize: 22, weight: .bold),
                                              textColor: .white)
    }
}

// MARK: - Actions
private extension PurchaseDomainProfileTopInfoCell {
    @IBAction func addAvatarButtonPressed() {
        buttonPressedCallback?(.avatar)
    }
    
    @IBAction func addCoverButtonPressed() {
        buttonPressedCallback?(.banner)
    }
}
