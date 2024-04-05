//
//  WalletDetailsTopInfoCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.05.2022.
//

import UIKit

final class WalletDetailsTopInfoCell: UICollectionViewCell {

    @IBOutlet private weak var walletImageContainerView: ResizableRoundedWalletImageView!
    @IBOutlet private weak var walletNameLabel: UILabel!
    @IBOutlet private weak var copyAddressButton: TextTertiaryButton!
    
    @IBOutlet private weak var walletTitleStackView: UIStackView!
    @IBOutlet private weak var externalWalletIndicator: UIImageView!
    
    @IBOutlet private weak var domainBadgeView: GenericBadgeView!

    var copyAddressButtonPressedCallback: EmptyCallback?
    var externalBadgePressedCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        copyAddressButton.imageLayout = .trailing
        domainBadgeView.layer.cornerRadius = domainBadgeView.bounds.height / 2
        domainBadgeView.isUserInteractionEnabled = true
        domainBadgeView.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(externalBadgePressed))
        walletTitleStackView.addGestureRecognizer(tap)
    }
    
}

// MARK: - Open methods
extension WalletDetailsTopInfoCell {
    func setWith(walletInfo: WalletDisplayInfo, domain: DomainDisplayInfo?, isUpdating: Bool) {
        accessibilityIdentifier = "Wallet Details Collection Cell Info \(walletInfo.displayName)"
        walletImageContainerView.setWith(walletInfo: walletInfo)
        walletNameLabel.setAttributedTextWith(text: walletInfo.displayName,
                                              font: .currentFont(withSize: 32,
                                                                 weight: .bold),
                                              textColor: .foregroundDefault,
                                              lineBreakMode: .byTruncatingTail)
        
        switch walletInfo.source {
        case .external:
            externalWalletIndicator.isHidden = false
            copyAddressButton.setTitle(walletInfo.address.walletAddressTruncated, image: .copyToClipboardIcon)
            // TODO: - MPC
        case .imported, .locallyGenerated, .mpc:
            externalWalletIndicator.isHidden = true
            
            if walletInfo.isNameSet {
                copyAddressButton.setTitle(walletInfo.address.walletAddressTruncated, image: .copyToClipboardIcon)
            } else {
                copyAddressButton.setTitle(String.Constants.copy.localized(), image: .copyToClipboardIcon)
            }
        }
        if let domain = domain {
            domainBadgeView.setWith(domain: domain, isUpdating: isUpdating)
        }
        walletTitleStackView.isUserInteractionEnabled = !externalWalletIndicator.isHidden
    }
}

// MARK: - Actions
private extension WalletDetailsTopInfoCell {
    @IBAction func didPressCopyAddressButton() {
        copyAddressButtonPressedCallback?()
    }
    
    @objc func externalBadgePressed() {
        externalBadgePressedCallback?()
    }
}
