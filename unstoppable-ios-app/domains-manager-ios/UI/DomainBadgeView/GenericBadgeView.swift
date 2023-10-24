//
//  GenericBadgeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.09.2022.
//

import UIKit

final class GenericBadgeView: UIControl, SelfNameable, NibInstantiateable {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet private weak var badgeImageView: KeepingAnimationImageView!
    @IBOutlet private weak var badgeNameLabel: UILabel!
    @IBOutlet private weak var badgeContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
}

// MARK: - Open methods
extension GenericBadgeView {
    func setWith(domain: DomainDisplayInfo,
                 isUpdating: Bool) {
        badgeImageView.layer.removeAllAnimations()
        setTextLabel(with: domain.name)
        if isUpdating {
            badgeImageView.image = .refreshIcon
            badgeImageView.runUpdatingRecordsAnimation()
        } else {
            Task {
                badgeImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domain,
                                                                                                         size: .default),
                                                                                   downsampleDescription: nil)
                let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain,
                                                                                                   size: .default),
                                                                           downsampleDescription: .icon)
                badgeImageView.image = image
            }
        }
    }
    
    func setWith(externalWalletIcon: UIImage, address: String) {
        setTextLabel(with: address.walletAddressTruncated)
        badgeImageView.image = externalWalletIcon
    }
}

// MARK: - Private methods
private extension GenericBadgeView {
    @objc func didTapBadge() {
        sendActions(for: .touchUpInside)
    }
    
    func setTextLabel(with text: String) {
        badgeNameLabel.setAttributedTextWith(text: text,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .foregroundSecondary,
                                              lineBreakMode: .byTruncatingTail)
    }
}

// MARK: - Setup methods
private extension GenericBadgeView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        containerView.backgroundColor = .clear
        badgeContainerView.layer.cornerRadius = 16
        badgeImageView.tintColor = .foregroundSecondary
        badgeContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBadge)))
    }
}
