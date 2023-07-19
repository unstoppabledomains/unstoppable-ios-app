//
//  ChatListDomainSelectionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import UIKit

final class ChatListDomainSelectionCell: UICollectionViewCell {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var badgeView: UnreadMessagesBadgeView!
    
    private var isDomainSelected = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        badgeView.setConstraints()
        clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        setContainerShadow()
    }
}

// MARK: - Open methods
extension ChatListDomainSelectionCell {
    func setWith(configuration: ChatsListViewController.DomainSelectionUIConfiguration) {
        isDomainSelected = configuration.isSelected
        setContainerShadow()
        
        let domain = configuration.domain
        if isDomainSelected {
            loadDomainImageFor(domain: domain)
        }
        iconImageView.isHidden = !isDomainSelected
        
        badgeView.setUnreadMessagesCount(configuration.unreadMessagesCount)
        
        let nameLabelColor: UIColor = isDomainSelected ? .foregroundDefault : .foregroundSecondary
        domainNameLabel.setAttributedTextWith(text: domain.name,
                                              font: .currentFont(withSize: 14, weight: .medium),
                                              textColor: nameLabelColor,
                                              lineBreakMode: .byTruncatingTail)
        
        containerView.backgroundColor = isDomainSelected ? .backgroundOverlay : .clear
    }
}

// MARK: - Private methods
private extension ChatListDomainSelectionCell {
    func setContainerShadow() {
        if isDomainSelected {
            containerView.applyFigmaShadow(style: .xSmall)
        } else {
            containerView.layer.shadowPath = nil
        }
    }
    
    func loadDomainImageFor(domain: DomainDisplayInfo) {
        if domain.pfpSource != .none,
           let image = appContext.imageLoadingService.cachedImage(for: .domain(domain)) {
            iconImageView.image = image
        } else {
            Task {
                let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain, size: .default),
                                                                           downsampleDescription: nil)
                iconImageView.image = image
            }
        }
    }
}
