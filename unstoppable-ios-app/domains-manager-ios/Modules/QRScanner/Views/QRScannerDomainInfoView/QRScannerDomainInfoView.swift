//
//  QRScannerDomainInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.06.2022.
//

import Foundation
import UIKit

final class QRScannerDomainInfoView: UIControl, SelfNameable, NibInstantiateable {
    
    @IBOutlet var containerView: UIView!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var backgroundContainerView: UIView!
    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private var domainInfoLabel: UILabel!
    @IBOutlet private var walletInfoLabel: UILabel!
    @IBOutlet private weak var walletLoadingView: BlinkingView!
    @IBOutlet private weak var chevronImageView: UIImageView!
    @IBOutlet private weak var reverseResolutionIndicator: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        backgroundContainerView.backgroundColor = .white.withAlphaComponent(0.08)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        backgroundContainerView.backgroundColor = .clear
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        backgroundContainerView.backgroundColor = .clear
    }
}

// MARK: - Open methods
extension QRScannerDomainInfoView {
    func setWith(wallet: WalletEntity, isSelectable: Bool) {
        reverseResolutionIndicator.isHidden = true
        let title: String
        let subtitle: String
        if let domain = wallet.rrDomain {
            title = domain.name
            subtitle = wallet.displayName
            reverseResolutionIndicator.isHidden = false
            
            Task {
                iconImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domain, size: .default),
                                                                                     downsampleDescription: nil)
                let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain, size: .default),
                                                                           downsampleDescription: .icon)
                iconImageView.image = image
            }
        } else {
            if wallet.displayInfo.isNameSet {
                title = wallet.displayName
                subtitle = wallet.address.walletAddressTruncated
            } else {
                title = wallet.address.walletAddressTruncated
                subtitle = ""
            }
            iconImageView.image = wallet.displayInfo.source.displayIcon
        }
        
        domainInfoLabel.setAttributedTextWith(text: title,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .brandWhite)
        
        isUserInteractionEnabled = isSelectable
        chevronImageView.isHidden = !isSelectable
        walletLoadingView.isHidden = true
        let subtitleText = subtitle.isEmpty ? "" : "· \(subtitle)"
        let balance = wallet.totalBalance
        let walletInfo = "$\(balance.rounded(toDecimalPlaces: 2)) \(subtitleText)"
        
        walletInfoLabel.setAttributedTextWith(text: walletInfo,
                                              font: .currentFont(withSize: 14, weight: .regular),
                                              textColor: .brandWhite.withAlphaComponent(0.56))
    }
}

// MARK: - Private methods
private extension QRScannerDomainInfoView {
    @objc func didTapSelf() {
        sendActions(for: .touchUpInside)
    }
}

// MARK: - Setup methods
private extension QRScannerDomainInfoView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        contentView.backgroundColor = .white.withAlphaComponent(0.16)
        contentView.layer.cornerRadius = 12
        backgroundContainerView.layer.cornerRadius = 8
        backgroundContainerView.backgroundColor = .clear
        reverseResolutionIndicator.isHidden = true
        chevronImageView.isHidden = true
        walletLoadingView.isHidden = true
        domainInfoLabel.text = ""
        walletInfoLabel.text = ""

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSelf))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tap)
    }
}
