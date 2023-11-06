//
//  ChooseReverseResolutionCollectionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.09.2022.
//

import UIKit

final class ChooseReverseResolutionCollectionCell: BaseListCollectionViewCell {

    
    @IBOutlet private weak var domainImageView: UIImageView!
    @IBOutlet private weak var reverseResolutionIndicatorImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var checkmark: UIImageView!
    @IBOutlet private weak var statusMessage: StatusMessage!
    @IBOutlet private weak var disabledCoverView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        subtitleLabel.setAttributedTextWith(text: String.Constants.currentlySet.localized(),
                                            font: .currentFont(withSize: 14, weight: .medium),
                                            textColor: .foregroundAccent)
    }
}

// MARK: - Open methods
extension ChooseReverseResolutionCollectionCell {
    func setWith(domain: DomainDisplayInfo, isSelected: Bool, isCurrent: Bool) {
        checkmark.isHidden = !isSelected
        reverseResolutionIndicatorImageView.isHidden = checkmark.isHidden
        titleLabel.setAttributedTextWith(text: domain.name,
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .foregroundDefault,
                                         lineBreakMode: .byTruncatingTail)
        set(isEnabled: true)
        subtitleLabel.isHidden = true
        statusMessage.isHidden = true
        
        if isCurrent {
            subtitleLabel.isHidden = false
        } else if domain.isUpdatingRecords {
            statusMessage.isHidden = false
            set(isEnabled: false)
            statusMessage.setComponent(.updatingRecords)
        }
        
        Task {
            domainImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domain,
                                                                                                         size: .default),
                                                                                   downsampleDescription: nil)
            let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain,
                                                                                               size: .default),
                                                                       downsampleDescription: .icon)
            domainImageView.image = image
        }
    }
}

// MARK: - Private methods
private extension ChooseReverseResolutionCollectionCell {
    func set(isEnabled: Bool) {
        disabledCoverView.isHidden = isEnabled
        isUserInteractionEnabled = isEnabled
    }
}
