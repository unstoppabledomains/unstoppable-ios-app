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
    
    @IBOutlet private weak var secondaryLabelStack: UIStackView!
    @IBOutlet private weak var secondaryLabel: UILabel!
    @IBOutlet private weak var loadingView: LoadingIndicatorView!
    
    @IBOutlet private weak var reverseResolutionStack: UIStackView!
    @IBOutlet private weak var walletImageContainerView: ResizableRoundedWalletImageView!
    @IBOutlet private weak var walletAddressLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        walletImageContainerView.clipsToBounds = false
        walletImageContainerView.tintColor = .foregroundSecondary
        set(indicator: nil)
    }
    
}

// MARK: - Open methods
extension DomainSelectionCell {
    func setWith(domain: DomainItem, isSelected: Bool, secondaryText: String? = nil, isLoading: Bool = false, indicator: Indicator? = nil) {
        secondaryLabelStack.isHidden = false
        reverseResolutionStack.isHidden = true
        checkmark.isHidden = !isSelected
        set(indicator: indicator)
        set(domainItem: domain)
        secondaryLabel.isHidden = secondaryText == nil
        secondaryLabel.setAttributedTextWith(text: secondaryText ?? "",
                                             font: .currentFont(withSize: 14, weight: .regular),
                                             textColor: .foregroundSecondary)
        loadingView.isHidden = !isLoading
        secondaryLabel.superview?.isHidden = secondaryLabel.isHidden && loadingView.isHidden
    }
    
    func setWith(domain: DomainItem, isSelected: Bool, walletInfo: WalletDisplayInfo, indicator: Indicator? = nil) {
        secondaryLabelStack.isHidden = true
        reverseResolutionStack.isHidden = false
        set(indicator: indicator)
        set(domainItem: domain)
        checkmark.isHidden = !isSelected
        walletImageContainerView.setWith(walletInfo: walletInfo, style: .small16)
        walletAddressLabel.setAttributedTextWith(text: walletInfo.address.walletAddressTruncated,
                                                 font: .currentFont(withSize: 14, weight: .medium),
                                                 textColor: .foregroundSecondary)
    }
    
    func setWith(domainName: String, isSelected: Bool) {
        secondaryLabel.superview?.isHidden = true
        checkmark.isHidden = !isSelected
        secondaryLabelStack.isHidden = true
        reverseResolutionStack.isHidden = true
        setDomainName(domainName)
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .initials(domainName, size: .default, style: .accent),
                                                                   downsampleDescription: nil)
            domainNameImageView.image = image
        }
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
    
    func set(domainItem: DomainItem) {
        setDomainName(domainItem.name)
        Task {
            domainNameImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domainItem,
                                                                                                         size: .default),
                                                                                   downsampleDescription: nil)
            let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domainItem,
                                                                                               size: .default),
                                                                       downsampleDescription: nil)
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
