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
    func setWith(domain: DomainDisplayInfo?, wallet: WalletDisplayInfo, balance: WalletTokenPortfolio?, isSelectable: Bool) {
        guard let domain else { return }
        // TODO: - Handle no domain
        Task {
            iconImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domain, size: .default),
                                                                                 downsampleDescription: nil)
            let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain, size: .default),
                                                                       downsampleDescription: .icon)
            iconImageView.image = image
        }
        
        reverseResolutionIndicator.isHidden = true
        if let reverseResolutionDomain = wallet.reverseResolutionDomain ,
           domain.name == reverseResolutionDomain.name {
            reverseResolutionIndicator.isHidden = false
        }
        
        isUserInteractionEnabled = isSelectable
        chevronImageView.isHidden = !isSelectable
        domainInfoLabel.setAttributedTextWith(text: domain.name,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .brandWhite)
        
        walletLoadingView.isHidden = balance != nil
        let walletInfo: String
        if let balance = balance {
            walletInfo = "\(wallet.displayName) · \(balance.value.walletUsd)"
        } else {
            walletInfo = "\(wallet.displayName) · "
        }
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
