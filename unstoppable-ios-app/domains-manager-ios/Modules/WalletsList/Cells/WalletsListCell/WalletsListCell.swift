//
//  WalletsListCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2022.
//

import UIKit

final class WalletsListCell: BaseListCollectionViewCell {

    @IBOutlet private weak var iconContainerView: ResizableRoundedImageView!
    @IBOutlet private weak var statusImageView: UIImageView!
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!
    @IBOutlet private weak var chevronContainerView: UIView!

}

// MARK: - Open methods
extension WalletsListCell {
    func setWith(item: WalletsListViewController.Item) {
        switch item {
        case .walletInfo(let walletInfo):
            accessibilityIdentifier = "Wallets List Collection Cell \(walletInfo.name)"
            chevronContainerView.isHidden = false
            statusImageView.isHidden = false
            showInfo(of: walletInfo)
            statusImageView.tintColor = walletInfo.backupState.tintColor
            statusImageView.image = walletInfo.backupState.icon
        
            if case.external = walletInfo.source {
                statusImageView.image = .externalWalletIndicator
                statusImageView.tintColor = .foregroundSecondary
            }
        case .selectableWalletInfo(let walletInfo, let isSelected):
            accessibilityIdentifier = "Wallets List Collection Cell Select \(walletInfo.name)"
            chevronContainerView.isHidden = true
            statusImageView.isHidden = false
            showInfo(of: walletInfo)
            statusImageView.tintColor = .foregroundAccent
            statusImageView.image = .checkCircle
            statusImageView.isHidden = !isSelected
        case .manageICloudBackups:
            accessibilityIdentifier = "Wallets List Collection Cell Manage iCloud Backups"
            chevronContainerView.isHidden = true
            statusImageView.isHidden = true
            secondaryLabel.isHidden = true
            iconContainerView.image = .cloudIcon
            iconContainerView.tintColor = .foregroundSecondary
            iconContainerView.setSize(.init(containerSize: 24, imageSize: 20))
            iconContainerView.setStyle(.smallImage)
            iconContainerView.layer.borderWidth = 0
            iconContainerView.backgroundColor = .clear
            
            primaryLabel.setAttributedTextWith(text: String.Constants.manageICloudBackups.localized(),
                                               font: .currentFont(withSize: 16, weight: .medium),
                                               textColor: .foregroundSecondary)
        case .empty:
            return
        }
    }
}

// MARK: - Private methods
private extension WalletsListCell {
    func showInfo(of walletInfo: WalletDisplayInfo) {
        primaryLabel.setAttributedTextWith(text: walletInfo.displayName,
                                           font: .currentFont(withSize: 16, weight: .medium),
                                           textColor: .foregroundDefault,
                                           lineHeight: 24,
                                           lineBreakMode: .byTruncatingTail)
        secondaryLabel.setAttributedTextWith(text: String.Constants.pluralNDomains.localized(walletInfo.domainsCount, walletInfo.domainsCount),
                                             font: .currentFont(withSize: 14, weight: .regular),
                                             textColor: .foregroundSecondary,
                                             lineHeight: 20)
        secondaryLabel.isHidden = walletInfo.domainsCount <= 0
        
        iconContainerView.backgroundColor = .backgroundMuted2
        iconContainerView.layer.borderWidth = 1
        iconContainerView.image = walletInfo.source.displayIcon
        iconContainerView.tintColor = .foregroundDefault
        iconContainerView.setSize(.init(containerSize: 40, imageSize: 20))
        switch walletInfo.source {
        case .imported, .locallyGenerated:
            iconContainerView.setStyle(.imageCentered)
        case .mpc:
            iconContainerView.setStyle(.imageCentered)
            iconContainerView.backgroundColor = .backgroundAccentEmphasis
            iconContainerView.tintColor = .foregroundOnEmphasis
            statusImageView.isHidden = true
        case .external:
            iconContainerView.setStyle(.largeImage)
        }
    }
}
