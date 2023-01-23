//
//  WalletInfoBadgeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.09.2022.
//

import Foundation
import UIKit

final class WalletInfoBadgeView: UIControl, SelfNameable, NibInstantiateable {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet private weak var walletImageContainerView: ResizableRoundedWalletBadgeImageView!
    @IBOutlet private weak var walletNameLabel: UILabel!
    @IBOutlet private weak var badgeContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    

}

// MARK: - Open methods
extension WalletInfoBadgeView {
    func setWith(walletInfo: WalletDisplayInfo) {
        walletImageContainerView.setWith(walletInfo: walletInfo, style: .indicatorSmall)
        walletNameLabel.setAttributedTextWith(text: walletInfo.displayName,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .foregroundSecondary,
                                              lineBreakMode: .byTruncatingTail)
    }
    
    // TODO: - Move to separate class
    func setWith(coin: CoinRecord) {
        walletImageContainerView.isHidden = true
        walletNameLabel.setAttributedTextWith(text: coin.ticker,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .foregroundSecondary)
    }
}

// MARK: - Private methods
private extension WalletInfoBadgeView {
    @objc func didTapBadge() {
        sendActions(for: .touchUpInside)
    }
}

// MARK: - Setup methods
private extension WalletInfoBadgeView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        containerView.backgroundColor = .clear
        walletImageContainerView.clipsToBounds = false
        badgeContainerView.layer.cornerRadius = 16
        badgeContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBadge)))
    }
}
