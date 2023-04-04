//
//  DomainProfileBadgeCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import UIKit

final class DomainProfileBadgeCell: BaseListCollectionViewCell {
    
    @IBOutlet private weak var badgeIconImageView: UIImageView!
    @IBOutlet private weak var iconSizeConstraint: NSLayoutConstraint!
    
    
    override var containerColor: UIColor { isExploreWeb3Badge ? .clear : .white.withAlphaComponent(0.16) }
    override var backgroundContainerColor: UIColor { .clear }
    private var isExploreWeb3Badge = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.borderWidth = 1
        badgeIconImageView.tintColor = .white
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.cornerRadius = bounds.height / 2
    }
}

// MARK: - Open methods
extension DomainProfileBadgeCell {
    func setWith(displayInfo: DomainProfileViewController.DomainProfileBadgeDisplayInfo) {
        iconSizeConstraint.constant = displayInfo.badge.isUDBadge ? 40 : 56
        badgeIconImageView.layer.cornerRadius = displayInfo.badge.isUDBadge ? 0 : 28
        set(badgeIcon: displayInfo.defaultIcon)
        if displayInfo.isExploreWeb3Badge {
            containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        } else {
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
    func set(badgeIcon: UIImage) {
        badgeIconImageView.image = badgeIcon
    }
}
