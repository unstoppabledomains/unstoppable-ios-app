//
//  AppearanceSettingsCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import UIKit

final class AppearanceSettingsCell: BaseListCollectionViewCell {
    
    @IBOutlet private weak var imageContainerView: ResizableRoundedImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageContainerView.setSize(.init(containerSize: 40, imageSize: 20))
        imageContainerView.setStyle(.imageCentered)
        imageContainerView.tintColor = .foregroundDefault
    }
    
    func setWith(item: AppearanceSettingsViewController.Item) {
        switch item {
        case .theme(let theme):
            nameLabel.setAttributedTextWith(text: String.Constants.settingsAppearanceTheme.localized(),
                                            font: .currentFont(withSize: 16, weight: .medium),
                                            textColor: .foregroundDefault)
            imageContainerView.image = .settingsIconAppearance
            valueLabel.setAttributedTextWith(text: theme.visibleName,
                                            font: .currentFont(withSize: 16, weight: .regular),
                                            textColor: .foregroundSecondary)
        }
    }

}
