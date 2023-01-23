//
//  SocialsDomainImagePreviewView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.06.2022.
//

import UIKit

final class SocialsDomainImagePreviewView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var domainSharingCardView: UDDomainSharingCardView!
    
    private var saveDomainImageDescription: SaveDomainImageDescription?

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

// MARK: - SaveDomainImagePreviewProvider
extension SocialsDomainImagePreviewView: SaveDomainImagePreviewProvider {
    var title: String { String.Constants.card.localized() }
    
    func setPreview(with saveDomainImageDescription: SaveDomainImageDescription) {
        self.saveDomainImageDescription = saveDomainImageDescription
        backgroundImageView.image = saveDomainImageDescription.originalDomainImage
        domainSharingCardView.setWith(domain: saveDomainImageDescription.domain,
                                      qrImage: saveDomainImageDescription.qrImage)
    }
    
    func finalImage() -> UIImage? {
        guard let saveDomainImageDescription = self.saveDomainImageDescription else { return nil }
        
        let size: CGFloat = 1024
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        containerView.overrideUserInterfaceStyle = UserDefaults.appearanceStyle
        containerView.backgroundColor = .systemBackground
        
        let bgImageView = UIImageView(frame: containerView.bounds)
        bgImageView.image = saveDomainImageDescription.originalDomainImage
        
        let blurView = UIVisualEffectView(frame: containerView.bounds)
        blurView.overrideUserInterfaceStyle = UserDefaults.appearanceStyle
        blurView.effect = UIBlurEffect(style: .systemThickMaterial)

        let watchSharingCard = UDDomainSharingCardView(frame: CGRect(x: 190, y: 100, width: 644, height: 824))
        watchSharingCard.setWith(domain: saveDomainImageDescription.domain,
                                 avatarImage: saveDomainImageDescription.originalDomainImage,
                                 qrImage: saveDomainImageDescription.qrImage)
        watchSharingCard.setNeedsLayout()
        watchSharingCard.layoutIfNeeded()
        
        let shadow1View = UIView(frame: watchSharingCard.frame)
        let shadow2View = UIView(frame: watchSharingCard.frame)
        
        [shadow1View, shadow2View].forEach { view in
            view.backgroundColor = .clear
            view.layer.cornerRadius = 36
        }
        shadow1View.applyFigmaShadow(x: 0, y: 4,
                                     blur: 8,
                                     spread: 0.01,
                                     color: .black,
                                     alpha: 0.12)
        shadow2View.applyFigmaShadow(x: 0, y: 40,
                                     blur: 80,
                                     spread: 0.01,
                                     color: .black,
                                     alpha: 0.24)

        containerView.addSubview(bgImageView)
        containerView.addSubview(blurView)
        containerView.addSubview(shadow1View)
        containerView.addSubview(shadow2View)
        containerView.addSubview(watchSharingCard)
        
        return containerView.renderedImage()
    }
}

// MARK: - Setup methods
private extension SocialsDomainImagePreviewView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
    }
}

