//
//  UDDomainSharingCardView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.06.2022.
//

import Foundation
import UIKit

final class UDDomainSharingCardView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var bgImageView: UIImageView!
    @IBOutlet private weak var bgGradientView: GradientView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var avatarImageContainerView: UIView!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var blurView: UIVisualEffectView!
    @IBOutlet private weak var tldLabel: UILabel!
    @IBOutlet private weak var tldDotLabel: UILabel!
    @IBOutlet private weak var imageOverlayView: UIView!
    @IBOutlet private weak var backgroundOpacityOverlayView: UIView!
    @IBOutlet private weak var qrCodeImageView: UIImageView!
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var bottomContentStackView: UIStackView!
    @IBOutlet private weak var contentStackTopConstraint: NSLayoutConstraint!
    @IBOutlet private var udLogoSideConstraints: [NSLayoutConstraint]!
    
    
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setupBlurEffect()
    }
    
    func setWith(domain: DomainItem, qrImage: UIImage) {
        setWith(domain: domain)
        setWith(qrImage: qrImage)
        Task {
            let avatarImage = await appContext.imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: nil)
            
            await MainActor.run {
                setWith(avatarImage: avatarImage)
            }
        }
    }
    
    func setWith(domain: DomainItem, avatarImage: UIImage, qrImage: UIImage) {
        setWith(domain: domain)
        setWith(qrImage: qrImage)
        setWith(avatarImage: avatarImage)
    }
}

// MARK: - Private methods
private extension UDDomainSharingCardView {
    func setWith(domain: DomainItem) {
        let domainName = domain.name
        let name = domainName.getBelowTld() ?? ""
        let domainTld = domainName.getTldName() ?? ""
        
        let scale = bounds.height / 256
        domainNameLabel.setAttributedTextWith(text: name.uppercased(),
                                              font: .helveticaNeueCustom(size: 24 * scale),
                                              letterSpacing: 0,
                                              textColor: .foregroundOnEmphasis,
                                              lineHeight: 24 * scale,
                                              lineBreakMode: .byTruncatingTail)
        tldLabel.setAttributedTextWith(text: domainTld.uppercased(),
                                       font: .helveticaNeueCustom(size: 20 * scale),
                                       letterSpacing: 0,
                                       textColor: .clear,
                                       lineHeight: 20 * scale,
                                       lineBreakMode: .byTruncatingTail,
                                       strokeColor: .foregroundOnEmphasis,
                                       strokeWidth: 3)
        tldDotLabel.setAttributedTextWith(text: String.dotSeparator,
                                          font: .helveticaNeueCustom(size: 20 * scale),
                                          letterSpacing: 0,
                                          textColor: .clear,
                                          lineHeight: 20 * scale,
                                          lineBreakMode: .byTruncatingTail,
                                          strokeColor: .foregroundOnEmphasis,
                                          strokeWidth: 3)
        contentView.layer.cornerRadius = 12 * scale
        avatarImageContainerView.layer.cornerRadius = 8 * scale
        layer.cornerRadius = contentView.layer.cornerRadius
        contentStackView.spacing = 10 * scale
        bottomContentStackView.spacing = 4 * scale
        contentStackTopConstraint.constant = 12 * scale
        udLogoSideConstraints.forEach { constraint in
            constraint.constant = 8 * scale
        }
    }
    
    func setWith(qrImage: UIImage) {
        qrCodeImageView.image = qrImage.transparentImage()
    }
    
    func setWith(avatarImage: UIImage?) {
        let imageToUse = avatarImage ?? .domainSharePlaceholder
        imageOverlayView.isHidden = avatarImage == nil
        bgImageView.image = avatarImage ?? UIColor.backgroundAccentEmphasis.image()
        avatarImageView.image = imageToUse
    }
}

// MARK: - Setup methods
private extension UDDomainSharingCardView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        clipsToBounds = true
        domainNameLabel.adjustsFontSizeToFitWidth = true
        domainNameLabel.minimumScaleFactor = Constants.domainNameMinimumScaleFactor
        bgGradientView.gradientDirection = .topRightToBottomLeft
        bgGradientView.gradientColors = [.white.withAlphaComponent(0.12), .white.withAlphaComponent(0.001)]
        borderWidth = 1
        borderColor = UIColor.white.withAlphaComponent(0.08)
        avatarImageContainerView.backgroundColor = .systemBackground
        setupBlurEffect()
    }
    
    func setupBlurEffect() {
        blurView.overrideUserInterfaceStyle = UserDefaults.appearanceStyle
        if UserDefaults.appearanceStyle == .dark {
            blurView.effect = UIBlurEffect(style: .systemMaterial)
            backgroundOpacityOverlayView.backgroundColor = .black.withAlphaComponent(0.1)
        } else {
            blurView.effect = UIBlurEffect(style: .systemMaterialDark)
            backgroundOpacityOverlayView.backgroundColor = .black.withAlphaComponent(0.46)
        }
    }
}
