//
//  MintDomainsConfigurationSelectionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import UIKit

final class MintDomainsConfigurationSelectionCell: BaseListCollectionViewCell {

    @IBOutlet private weak var domainNameImageView: UIImageView!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var checkbox: UDCheckBox!
    @IBOutlet private weak var disabledCoverView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        checkbox.isUserInteractionEnabled = false
    }

}

// MARK: - Open methods
extension MintDomainsConfigurationSelectionCell {
    func setWith(configuration: MintDomainsConfigurationViewController.ListItemConfiguration) {
        let domain = configuration.domain
        checkbox.isOn = configuration.isSelected
        
        switch configuration.state {
        case .normal:
            set(isEnabled: true)
            errorLabel.isHidden = true
        case .disabled:
            set(isEnabled: false)
            errorLabel.isHidden = true
        case .deprecated:
            set(isEnabled: false)
            errorLabel.isHidden = false
            errorLabel.setAttributedTextWith(text: String.Constants.deprecated.localized(),
                                             font: .currentFont(withSize: 12,
                                                                weight: .medium),
                                             textColor: .foregroundDanger)
        }
        
        if configuration.isSelected {
            checkbox.isEnabled = true
        }
        
        checkbox.isUserInteractionEnabled = false
        domainNameLabel.setAttributedTextWith(text: domain,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .foregroundDefault,
                                              lineBreakMode: .byTruncatingTail)
        
        
        if let cachedImage = appContext.imageLoadingService.cachedImage(for: .initials(domain,
                                                                                   size: .default,
                                                                                   style: .accent)) {
            domainNameImageView.image = cachedImage
        } else {
            Task.detached(priority: .background) { [weak self] in
                await Task.sleep(seconds: 0.25)
                let image = await appContext.imageLoadingService.loadImage(from: .initials(domain,
                                                                                       size: .default,
                                                                                       style: .accent),
                                                                           downsampleDescription: .icon)
                await self?.updateImage(image)
            }
        }
    }
}

// MARK: - Private methods
private extension MintDomainsConfigurationSelectionCell {
    @MainActor
    func updateImage(_ image: UIImage?) {
        self.domainNameImageView.image = image
    }
    
    func set(isEnabled: Bool) {
        checkbox.isEnabled = isEnabled
        disabledCoverView.isHidden = isEnabled
        isUserInteractionEnabled = isEnabled
    }
}

extension MintDomainsConfigurationSelectionCell {
    enum State: Hashable {
        case normal, disabled, deprecated
    }
}
