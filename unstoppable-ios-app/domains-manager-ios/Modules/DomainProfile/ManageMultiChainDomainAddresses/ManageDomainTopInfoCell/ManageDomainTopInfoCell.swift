//
//  ManageDomainTopInfoCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import UIKit

final class ManageDomainTopInfoCell: UICollectionViewCell {

    
    @IBOutlet private weak var domainAvatarImageView: UIImageView!
    @IBOutlet private weak var domainNameLabel: UILabel!

    @IBOutlet private weak var walletInfoBadgeView: WalletInfoBadgeView!

    @IBOutlet private weak var primaryDomainLabel: UILabel!
    @IBOutlet private weak var primaryDomainView: UIView!
    
    @IBOutlet private weak var missingRecordsStack: UIStackView!
    @IBOutlet private weak var missingRecordsLabel: UILabel!
    
    var walletPressedCallback: EmptyCallback?
    var primaryDomainPressedCallback: EmptyCallback?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        primaryDomainView.layer.cornerRadius = 16
        domainAvatarImageView.clipsToBounds = true
        domainAvatarImageView.layer.cornerRadius = 40
        primaryDomainLabel.setAttributedTextWith(text: String.Constants.settingsHomeScreen.localized(),
                                                 font: .currentFont(withSize: 16, weight: .medium),
                                                 textColor: .foregroundSecondary)
        walletInfoBadgeView.addTarget(self, action: #selector(didTapWalletInfo), for: .touchUpInside)
        primaryDomainView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPrimaryDomainView)))
    }

}

// MARK: - Open methods
extension ManageDomainTopInfoCell {
    func setWith(coin: CoinRecord) {
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .currency(coin,
                                                                                       size: .default,
                                                                                       style: .gray),
                                                                       downsampleDescription: nil)
            domainAvatarImageView.image = image
        }
        missingRecordsStack.isHidden = true
        domainNameLabel.setAttributedTextWith(text: coin.name,
                                              font: .currentFont(withSize: 32, weight: .bold),
                                              textColor: .foregroundDefault)
        
        primaryDomainView.isHidden = true
        walletInfoBadgeView.setWith(coin: coin)
    }
}
// MARK: - Actions
private extension ManageDomainTopInfoCell {
    @IBAction func didTapWalletInfo() {
        walletPressedCallback?()
    }
    
    @objc func didTapPrimaryDomainView() {
        primaryDomainPressedCallback?()
    }
}
