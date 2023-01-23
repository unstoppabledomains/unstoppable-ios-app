//
//  WallpaperDomainImagePreviewView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.06.2022.
//

import Foundation
import UIKit

final class WallpaperDomainImagePreviewView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!
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
extension WallpaperDomainImagePreviewView: SaveDomainImagePreviewProvider {
    var title: String { String.Constants.wallpaper.localized() }
    
    func setPreview(with saveDomainImageDescription: SaveDomainImageDescription) {
        self.saveDomainImageDescription = saveDomainImageDescription

        timeLabel.setAttributedTextWith(text: time,
                                        font: .currentFont(withSize: 14, weight: .regular),
                                        textColor: .black)
        backgroundImageView.image = saveDomainImageDescription.originalDomainImage
        domainSharingCardView.setWith(domain: saveDomainImageDescription.domain,
                                      qrImage: saveDomainImageDescription.qrImage)
    }
    
    func finalImage() -> UIImage? {
        guard let saveDomainImageDescription = self.saveDomainImageDescription else { return nil }
        
        let scale: CGFloat = 2
        let containerSize = multiply(size: UIScreen.main.bounds.size,
                                     by: scale)
            
        let containerView = UIView(frame: CGRect(origin: .zero, size: containerSize))
        containerView.overrideUserInterfaceStyle = UserDefaults.appearanceStyle
        containerView.backgroundColor = .systemBackground
        
        let bgImageView = UIImageView(frame: containerView.bounds)
        bgImageView.image = saveDomainImageDescription.originalDomainImage
        
        let blurView = UIVisualEffectView(frame: containerView.bounds)
        blurView.overrideUserInterfaceStyle = UserDefaults.appearanceStyle
        blurView.effect = UIBlurEffect(style: .systemThickMaterial)
        
        let cardRawSize: CGSize
        switch deviceSize {
        case .i4Inch:
            cardRawSize = CGSize(width: 260, height: 332)
        default:
            cardRawSize = CGSize(width: 304, height: 388)
        }
        let cardScaledSize = multiply(size: cardRawSize, by: scale)
        let cardOriginX = (containerSize.width - cardScaledSize.width) / 2
        let yOffsetCoefficient: CGFloat
        switch deviceSize {
        case .i4Inch, .i4_7Inch, .i5_5Inch:
            yOffsetCoefficient = 87.5/139.5
        default:
            yOffsetCoefficient = 58/228
        }
        let cardOriginY = ((containerSize.height - cardScaledSize.height) / 2) * (1 + yOffsetCoefficient)
        let cardScaledOrigin = CGPoint(x: cardOriginX,
                                       y: cardOriginY)
        
        let watchSharingCard = UDDomainSharingCardView(frame: CGRect(origin: cardScaledOrigin,
                                                                     size: cardScaledSize))
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
                                     blur: 16,
                                     spread: 0.01,
                                     color: .black,
                                     alpha: 0.08)
        
        shadow2View.applyFigmaShadow(x: 0, y: 16,
                                     blur: 48,
                                     spread: 0.01,
                                     color: .black,
                                     alpha: 0.16)
        
        containerView.addSubview(bgImageView)
        containerView.addSubview(blurView)
        containerView.addSubview(shadow1View)
        containerView.addSubview(shadow2View)
        containerView.addSubview(watchSharingCard)
        
        return containerView.renderedImage()
    }
    
    func multiply(size: CGSize, by multiplier: CGFloat) -> CGSize {
        return CGSize(width: size.width * multiplier, height: size.height * multiplier)
    }
}

// MARK: - Setup methods
private extension WallpaperDomainImagePreviewView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
    }
}

