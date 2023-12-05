//
//  BaseDomainProfileTopInfoCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import UIKit

class BaseDomainProfileTopInfoCell: UICollectionViewCell {
    
    @IBOutlet private(set) weak var domainAvatarImageView: UIImageView!
    @IBOutlet private(set) weak var domainBannerImageView: UIImageView!
    @IBOutlet private weak var avatarContainerView: UIView!
    @IBOutlet private weak var bannerTopConstraint: NSLayoutConstraint!

    private(set) var avatarStyle: DomainAvatarImageView.AvatarStyle = .circle
    private(set) var buttonPressedCallback: DomainProfileTopInfoButtonCallback?
    private(set) var avatarDropCallback: ImageDropCallback?
    private(set) var bannerDropCallback: ImageDropCallback?
    
    var minBannerOffset: CGFloat { 0 }
    var avatarPlaceholder: UIImage? { nil }
    
    override func layoutSubviews() {
        self.clipsToBounds = false
        super.layoutSubviews()
        
        DispatchQueue.main.async {
            self.setAvatarImageViewMask()
        }
        bannerTopConstraint.constant = minBannerOffset
    }
    
    func set(with data: DomainProfileViewController.ItemTopInfoData) {
        self.buttonPressedCallback = data.buttonPressedCallback
        self.avatarDropCallback = data.avatarDropCallback
        self.bannerDropCallback = data.bannerDropCallback
        
        switch data.avatarImageState {
        case .untouched(let source):
            switch source {
            case .image(_, let imageType), .imageURL(_, let imageType):
                switch imageType {
                case .onChain:
                    self.avatarStyle = .hexagon
                case .offChain, .default:
                    self.avatarStyle = .circle
                }
            case .none:
                self.avatarStyle = .circle
            }
        case .changed, .removed:
            self.avatarStyle = .circle
        }
        setAvatarImageViewMask()
        
        setImageFor(state: data.avatarImageState,
                    in: domainAvatarImageView,
                    placeholder: avatarPlaceholder)

        setImageFor(state: data.bannerImageState,
                    in: domainBannerImageView,
                    placeholder: nil)
    }
    
    func setImageFor(state: DomainProfileTopInfoData.ImageState,
                     in imageView: UIImageView,
                     placeholder: UIImage?) {
        imageView.image = placeholder
        Task {
            switch state {
            case .untouched(source: let source):
                switch source {
                case .image(let image, _):
                    imageView.image = image
                case .imageURL(let url, _):
                    let image = await appContext.imageLoadingService.loadImage(from: .url(url,
                                                                                          maxSize: Constants.downloadedImageMaxSize),
                                                                               downsampleDescription: .mid)
                    imageView.image = image
                case .none:
                    imageView.image = placeholder
                }
            case .changed(let image):
                imageView.image = image
            case .removed:
                imageView.image = placeholder
            }
        }
    }
    
}

// MARK: - ScrollViewOffsetListener
extension BaseDomainProfileTopInfoCell: ScrollViewOffsetListener {
    func didScrollTo(offset: CGPoint) {
        let yOffset = offset.y
        let bannerTopSpace = min(yOffset, minBannerOffset)
        if bannerTopConstraint.constant != bannerTopSpace {
            UIView.performWithoutAnimation {
                bannerTopConstraint.constant = bannerTopSpace
                layoutIfNeeded()
                setAvatarImageViewMask()
            }
        }
    }
}

// MARK: - Avatar mask
private extension BaseDomainProfileTopInfoCell {
    func setAvatarImageViewMask() {
        let maskLayer = CAShapeLayer()
        let bezier = UIBezierPath(rect: domainBannerImageView.bounds)
        let maskLineOffset: CGFloat = 4
        let bannerViewFrame = domainBannerImageView.convert(domainBannerImageView.frame, to: self)
        let avatarViewFrame = domainAvatarImageView.convert(domainAvatarImageView.bounds,
                                                            to: self)
        let avatarCoveringHeight: CGFloat = bannerViewFrame.maxY - avatarViewFrame.minY
        let maskLineCornerRadius: CGFloat = 12
        
        switch avatarStyle {
        case .circle:
            avatarContainerView.layer.mask = nil
            avatarContainerView.layer.cornerRadius = avatarContainerView.bounds.width / 2
            let bezierTopOffset: CGFloat = maskLineOffset + avatarCoveringHeight
            
            let circlePath = UIBezierPath()
            circlePath.move(to: CGPoint(x: avatarViewFrame.minX - maskLineOffset - maskLineCornerRadius,
                                        y: domainBannerImageView.bounds.height))
            circlePath.addCurve(to: CGPoint(x: domainBannerImageView.center.x,
                                            y: domainBannerImageView.bounds.height - bezierTopOffset + bannerTopConstraint.constant),
                                controlPoint1: CGPoint(x: avatarViewFrame.minX + 1,
                                                       y: domainBannerImageView.bounds.height + 3),
                                controlPoint2: CGPoint(x: avatarViewFrame.minX + maskLineOffset,
                                                       y: domainBannerImageView.bounds.height - bezierTopOffset + bannerTopConstraint.constant))
            
            circlePath.addCurve(to: CGPoint(x: avatarViewFrame.maxX + maskLineOffset + maskLineCornerRadius,
                                            y: domainBannerImageView.bounds.height),
                                controlPoint1: CGPoint(x: avatarViewFrame.maxX - 3,
                                                       y: domainBannerImageView.bounds.height - bezierTopOffset + 1 + bannerTopConstraint.constant),
                                controlPoint2: CGPoint(x: avatarViewFrame.maxX - maskLineOffset,
                                                       y: domainBannerImageView.bounds.height))
            bezier.append(circlePath)
        case .hexagon:
            avatarContainerView.layer.cornerRadius = 0
            let hexagonPath = DomainAvatarImageView.roundedPolygonPath(rect: avatarContainerView.bounds, lineWidth: 0,
                                                                       sides: 6,
                                                                       cornerRadius: maskLineCornerRadius)
            let avaMaskLayer = CAShapeLayer()
            avaMaskLayer.path = hexagonPath.cgPath
            avaMaskLayer.fillRule = .evenOdd
            avatarContainerView.layer.mask = avaMaskLayer
            
            let avatarSize = avatarContainerView.bounds.size
            let avatarWithLineSize = avatarSize.width + (maskLineOffset * 2)
            let scale: CGFloat = avatarWithLineSize / avatarSize.width
            hexagonPath.apply(CGAffineTransform(scaleX: scale, y: scale))
            
            let yOffset = domainBannerImageView.bounds.height - avatarCoveringHeight - maskLineOffset + bannerTopConstraint.constant
            let xOffset = (domainBannerImageView.bounds.width / 2) - (avatarWithLineSize / 2)
            hexagonPath.apply(CGAffineTransform(translationX: xOffset, y: yOffset))
            
            bezier.append(hexagonPath)
        }
        
        maskLayer.path = bezier.cgPath
        maskLayer.fillRule = .evenOdd
        
        domainBannerImageView.layer.mask = maskLayer
    }
}
