//
//  DomainsCollectionListCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

final class DomainsCollectionListCell: BaseListCollectionViewCell {

    @IBOutlet private weak var iconContainerView: IconBorderedContainerView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var statusMessage: StatusMessage!
    @IBOutlet private weak var reverseResolutionIndicatorImageView: UIImageView!
    
    @IBOutlet weak var chevronImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        iconImageView.layer.cornerRadius = 20
    }
    
}

// MARK: - Open methods
extension DomainsCollectionListCell {
    func setWith(domainItem: DomainDisplayInfo, isSelectable: Bool) {
        setIsSelectable(isSelectable)
        
        if domainItem.pfpSource != .none,
           let image = appContext.imageLoadingService.cachedImage(for: .domain(domainItem)) {
            iconImageView.image = image
        } else {
            Task {
                iconImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domainItem, size: .default),
                                                                                     downsampleDescription: nil)
                let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domainItem, size: .default),
                                                                           downsampleDescription: nil)
                iconImageView.image = image
            }
        }
        
        setPrimaryLabelWith(name: domainItem.name)
        
        switch domainItem.usageType {
        case .zil:
            statusMessage.setComponent(.bridgeDomainToPolygon)
            statusMessage.isHidden = false
        case .deprecated(let tld):
            statusMessage.setComponent(.deprecated(tld: tld))
            statusMessage.isHidden = false
        case .newNonInteractable:
            statusMessage.isHidden = true
        case .normal:
            statusMessage.setComponent(.updatingRecords)
            statusMessage.isHidden = !domainItem.isUpdatingRecords
        case .parked(let status):
            statusMessage.setComponent(.parked(status: status))
            statusMessage.isHidden = false
        }
        reverseResolutionIndicatorImageView.isHidden = !domainItem.isSetForRR
    }
    
    func setWith(searchDomain: SearchDomainProfile, isSelectable: Bool) {
        setIsSelectable(isSelectable)
        
        Task {
            iconImageView.image = await appContext.imageLoadingService.loadImage(from: .initials(searchDomain.name,
                                                                                                 size: .default,
                                                                                                 style: .accent),
                                                                                 downsampleDescription: nil)
            if let path = searchDomain.imagePath,
                let image = await appContext.imageLoadingService.loadImage(from: .domainPFPSource(.nonNFT(imagePath: path)),
                                                                           downsampleDescription: nil) {
                iconImageView.image = image
            }
        }
        setPrimaryLabelWith(name: searchDomain.name)
        statusMessage.isHidden = true
        reverseResolutionIndicatorImageView.isHidden = true
    }
}

// MARK: - Private methods
private extension DomainsCollectionListCell {
    func setIsSelectable(_ isSelectable: Bool) {
        self.isSelectable = isSelectable
        chevronImageView.isHidden = !isSelectable
    }
    
    func setPrimaryLabelWith(name: String) {
        primaryLabel.setAttributedTextWith(text: name,
                                           font: .currentFont(withSize: 16, weight: .medium),
                                           textColor: .foregroundDefault,
                                           lineHeight: 24,
                                           lineBreakMode: .byTruncatingTail)
    }
}
