//
//  SettingsCollectionViewCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit

final class SettingsCollectionViewCell: BaseListCollectionViewCell {

    @IBOutlet private weak var iconContainerView: IconBorderedContainerView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!
    @IBOutlet private weak var chevronContainerView: UIView!
    @IBOutlet private weak var switcher: UISwitch!

    var switcherValueChangedCallback: ((Bool)->())?
    
}

// MARK: - Open methods
extension SettingsCollectionViewCell {
    func setWith(loginProvider: LoginProvider) {
        setTitle(String.Constants.loginWithProviderN.localized(loginProvider.title))
        iconImageView.image = loginProvider.icon
        chevronContainerView.isHidden = false
        switcher.isHidden = true
        valueLabel.isHidden = true
        subtitleLabel.isHidden = true
        
        iconImageView.tintColor = .foregroundDefault
        iconContainerView.backgroundColor = .backgroundMuted2
    }
}

// MARK: - Private methods
private extension SettingsCollectionViewCell {
    @IBAction func switcherValueChanged() {
        switcherValueChangedCallback?(switcher.isOn)
    }
    
    func setTitle(_ title: String) {
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .foregroundDefault)
    }
    
    func setSubtitle(_ subtitle: String) {
        subtitleLabel.setAttributedTextWith(text: subtitle,
                                            font: .currentFont(withSize: 16, weight: .regular),
                                            textColor: .foregroundSecondary)
    }
    
    func setValue(_ value: String) {
        valueLabel.setAttributedTextWith(text: value,
                                         font: .currentFont(withSize: 16, weight: .regular),
                                         textColor: .foregroundSecondary,
                                         lineBreakMode: .byTruncatingTail)
    }
}
