//
//  ChoosePrimaryDomainCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

final class DomainSelectionCell: BaseListCollectionViewCell {
    
    @IBOutlet private weak var domainNameImageView: UIImageView!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var checkmark: UIImageView!
    @IBOutlet private weak var indicatorImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        set(indicator: nil)
    }
    
}

// MARK: - Open methods
extension DomainSelectionCell {
    func setWith(domain: DomainDisplayInfo, isSelected: Bool, indicator: Indicator? = nil) {
        checkmark.isHidden = !isSelected
        set(indicator: indicator)
        set(domainItem: domain)
    }
}

// MARK: - Private methods
private extension DomainSelectionCell {
    func setDomainName(_ domainName: String) {
        domainNameLabel.setAttributedTextWith(text: domainName,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .foregroundDefault,
                                              lineBreakMode: .byTruncatingTail)
    }
    
    func set(domainItem: DomainDisplayInfo) {
        setDomainName(domainItem.name)
        Task {
            domainNameImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domainItem,
                                                                                                         size: .default),
                                                                                   downsampleDescription: nil)
            let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domainItem,
                                                                                               size: .default),
                                                                       downsampleDescription: .icon)
            domainNameImageView.image = image
        }
    }
    
    func set(indicator: Indicator?) {
        indicatorImage.isHidden = indicator == nil
        indicatorImage.image = indicator?.icon
    }
}

extension DomainSelectionCell {
    enum Indicator {
        case reverseResolution
        
        var icon: UIImage {
            switch self {
            case .reverseResolution: return .reverseResolutionCircleSign
            }
        }
    }
}
