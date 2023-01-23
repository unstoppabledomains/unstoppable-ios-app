//
//  DomainProfileBadgeCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import UIKit

final class DomainProfileBadgeCell: BaseListCollectionViewCell {
    
    @IBOutlet private weak var badgeIconImageView: UIImageView!
    @IBOutlet private weak var badgeNameLabel: UILabel!
    @IBOutlet private weak var badgeDescriptionLabel: UILabel!
    
    override var containerColor: UIColor { isExploreWeb3Badge ? .clear : .white.withAlphaComponent(0.16) }
    override var backgroundContainerColor: UIColor { .clear }
    private var isExploreWeb3Badge = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.borderWidth = 1
        badgeIconImageView.tintColor = .white
    }
    
}

// MARK: - Open methods
extension DomainProfileBadgeCell {
    func setWith(displayInfo: DomainProfileViewController.DomainProfileBadgeDisplayInfo) {
        set(badgeIcon: displayInfo.defaultIcon)
        if displayInfo.isExploreWeb3Badge {
            badgeDescriptionLabel.isHidden = false
            set(badgeName: String.Constants.profileBadgeExploreWeb3TitleShort.localized())
            set(badgeDescription: String.Constants.profileBadgeExploreWeb3DescriptionShort.localized())
            containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        } else {
            badgeDescriptionLabel.isHidden = true
            set(badgeName: displayInfo.badge.name)
            containerView.layer.borderColor = UIColor.clear.cgColor
            Task {
                if let image = await displayInfo.loadBadgeIcon() {
                    set(badgeIcon: image)
                }
            }
        }
        
        self.isExploreWeb3Badge = displayInfo.isExploreWeb3Badge
        updateAppearance()
    }
}

// MARK: - Private methods
private extension DomainProfileBadgeCell {
    func set(badgeName: String) {
        badgeNameLabel.setAttributedTextWith(text: badgeName,
                                             font: .currentFont(withSize: 16, weight: .medium),
                                             textColor: .white,
                                             lineBreakMode: .byTruncatingTail)
    }
    
    func set(badgeDescription: String) {
        badgeDescriptionLabel.setAttributedTextWith(text: badgeDescription,
                                                    font: .currentFont(withSize: 12, weight: .medium),
                                                    textColor: .white.withAlphaComponent(0.56),
                                                    lineBreakMode: .byTruncatingTail)
    }
    
    func set(badgeIcon: UIImage) {
        badgeIconImageView.image = badgeIcon
    }
}
