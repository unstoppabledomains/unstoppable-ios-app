//
//  WalletDetailsListCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.05.2022.
//

import UIKit

final class WalletDetailsListCell: BaseListCollectionViewCell {

    @IBOutlet private weak var iconImageView: KeepingAnimationImageView!
    @IBOutlet private weak var statusImageView: UIImageView!
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!
    @IBOutlet private weak var disabledCoverView: UIView!
    
}

// MARK: - Open methods
extension WalletDetailsListCell {
    func setWith(item: WalletDetailsViewController.WalletDetailsListItem) {
        accessibilityIdentifier = "Wallet Details Collection Cell \(item.title)"
        statusImageView.isHidden = true
        secondaryLabel.isHidden = true
        iconImageView.tintColor = item.tintColor
        primaryLabel.setAttributedTextWith(text: item.title,
                                           font: .currentFont(withSize: 16, weight: .medium),
                                           textColor: item.tintColor)
        iconImageView.image = item.icon
        iconImageView.layer.removeAllAnimations()

        set(isEnabled: true)
        
        switch item {
        case .backUp(let state, let isOnline):
            switch state {
            case .locallyGeneratedNotBackedUp:
                statusImageView.isHidden = false
                statusImageView.image = state.icon
                statusImageView.tintColor = state.tintColor
                secondaryLabel.isHidden = false
                secondaryLabel.setAttributedTextWith(text: String.Constants.notBackedUp.localized(),
                                                     font: .currentFont(withSize: 14, weight: .medium),
                                                     textColor: state.tintColor,
                                                     lineHeight: 20)
                set(isOnline: isOnline)
            case .importedNotBackedUp:
                secondaryLabel.isHidden = false
                secondaryLabel.setAttributedTextWith(text: String.Constants.importedWalletBackupHint.localized(),
                                                     font: .currentFont(withSize: 14, weight: .regular),
                                                     textColor: state.tintColor,
                                                     lineHeight: 20)
                set(isOnline: isOnline)
            case .backedUp:
                isUserInteractionEnabled = false
            }
        case .reverseResolution(let state):
            switch state {
            case .notSet(let isEnabled):
                set(isEnabled: isEnabled)
                if !isEnabled {
                    set(subtitle: String.Constants.reverseResolutionUnavailableWhileRecordsUpdating.localized())
                }
            case .settingFor(let domain):
                let domainName = domain.name
                set(subtitle: domainName + " · " + String.Constants.pending.localized())
                iconImageView.runUpdatingRecordsAnimation()
            case .setFor(let domain, let isEnabled, let isUpdatingRecords):
                if isUpdatingRecords {
                    set(isEnabled: false )
                    set(subtitle: String.Constants.reverseResolutionUnavailableWhileRecordsUpdating.localized())
                } else {
                    let domainName = domain.name
                    set(subtitle: domainName)
                    isUserInteractionEnabled = isEnabled
                }
            }
        case .recoveryPhrase, .rename, .domains, .removeWallet:
            return
        case .importWallet:
            set(subtitle: String.Constants.connectWalletRecovery.localized())
        }
    }
}

// MARK: - Private methods
private extension WalletDetailsListCell {
    func set(isOnline: Bool) {
        if !isOnline {
            statusImageView.isHidden = true
            iconImageView.tintColor = .foregroundMuted
            primaryLabel.updateAttributesOf(text: primaryLabel.attributedString.string, textColor: .foregroundMuted)
            secondaryLabel.setAttributedTextWith(text: String.Constants.unavailableWhenOffline.localized(),
                                                 font: .currentFont(withSize: 14, weight: .regular),
                                                 textColor: .foregroundMuted,
                                                 lineHeight: 20)
        }
    }
    
    func set(subtitle: String) {
        secondaryLabel.isHidden = false
        secondaryLabel.setAttributedTextWith(text: subtitle,
                                             font: .currentFont(withSize: 14,
                                                                weight: .regular),
                                             textColor: .foregroundSecondary,
                                             lineBreakMode: .byTruncatingMiddle)
    }
    
    func set(isEnabled: Bool) {
        disabledCoverView.isHidden = isEnabled
        isUserInteractionEnabled = isEnabled
    }
}
