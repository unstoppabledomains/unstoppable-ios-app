//
//  RearrangeDomainCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.01.2023.
//

import UIKit

final class RearrangeDomainCell: BaseListCollectionViewCell {

    @IBOutlet private weak var domainImageView: UIImageView!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var rearrangeIcon: UIImageView!
    @IBOutlet private weak var rearrangeIconWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var indicatorImage: UIImageView!
    
    @IBOutlet private weak var reverseResolutionStack: UIStackView!
    @IBOutlet private weak var walletImageContainerView: ResizableRoundedWalletImageView!
    @IBOutlet private weak var walletAddressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isSelectable = false
        walletImageContainerView.clipsToBounds = false
        walletImageContainerView.tintColor = .foregroundSecondary
        indicatorImage.image = .reverseResolutionCircleSign
    }
}

// MARK: - Open methods
extension RearrangeDomainCell {
    func setWith(domain: DomainDisplayInfo,
                 reverseResolutionWalletInfo: WalletDisplayInfo?,
                 isSearching: Bool) {
        if let reverseResolutionWalletInfo {
            walletImageContainerView.setWith(walletInfo: reverseResolutionWalletInfo, style: .small16)
            walletAddressLabel.setAttributedTextWith(text: reverseResolutionWalletInfo.address.walletAddressTruncated,
                                                     font: .currentFont(withSize: 14, weight: .medium),
                                                     textColor: .foregroundSecondary)
        }
        reverseResolutionStack.isHidden = reverseResolutionWalletInfo == nil
        indicatorImage.isHidden = reverseResolutionWalletInfo == nil
        set(domainItem: domain)
        setIsSearching(isSearching)
    }
    
    func setWith(domainName: String) {
        reverseResolutionStack.isHidden = true
        indicatorImage.isHidden = true
        setDomainName(domainName)
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .initials(domainName, size: .default, style: .accent),
                                                                       downsampleDescription: nil)
            domainImageView.image = image
        }
    }
}

// MARK: - Private methods
private extension RearrangeDomainCell {
    func setDomainName(_ domainName: String) {
        domainNameLabel.setAttributedTextWith(text: domainName,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .foregroundDefault,
                                              lineBreakMode: .byTruncatingTail)
    }
    
    func set(domainItem: DomainDisplayInfo) {
        setDomainName(domainItem.name)
        Task {
            domainImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domainItem,
                                                                                                             size: .default),
                                                                                       downsampleDescription: nil)
            let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domainItem,
                                                                                                   size: .default),
                                                                       downsampleDescription: nil)
            domainImageView.image = image
        }
    }
    
    func setIsSearching(_ isSearching: Bool) {
        isSelectable = isSearching
        rearrangeIcon.image = isSearching ? .chevronRight : .dragIcon24
        rearrangeIconWidthConstraint.constant = isSearching ? 20 : 24
    }
}
