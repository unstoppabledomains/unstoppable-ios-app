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
        self.isSelectable = isSelectable
        chevronImageView.isHidden = !isSelectable
        
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
        
        primaryLabel.setAttributedTextWith(text: domainItem.name,
                                           font: .currentFont(withSize: 16, weight: .medium),
                                           textColor: .foregroundDefault,
                                           lineHeight: 24,
                                           lineBreakMode: .byTruncatingTail)
        
        switch domainItem.usageType {
        case .zil:
            statusMessage.setComponent(.bridgeDomainToPolygon)
            statusMessage.isHidden = false
        case .deprecated(let tld):
            statusMessage.setComponent(.deprecated(tld: tld))
            statusMessage.isHidden = false
        case .newNonInteractable:
            //statusMessage.setComponent()
            statusMessage.isHidden = false
        case .normal:
            statusMessage.setComponent(.updatingRecords)
            statusMessage.isHidden = !domainItem.isUpdatingRecords
        case .parked(let status):
            statusMessage.setComponent(.parked(status: status))
            statusMessage.isHidden = false
        }
        reverseResolutionIndicatorImageView.isHidden = !domainItem.isSetForRR
    }
}
