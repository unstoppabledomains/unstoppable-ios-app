//
//  UDDomainSharingWatchCardView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.06.2022.
//

import Foundation
import UIKit

final class UDDomainSharingWatchCardView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var avatarCoverView: UIView!
    @IBOutlet private weak var qrContainerView: UIView!
    @IBOutlet private weak var qrCodeImageView: UIImageView!
    @IBOutlet private weak var bgGradientView: GradientView!
    
    @IBOutlet private var qrCodeOffsetConstraints: [NSLayoutConstraint]!
    
    
    
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
    
    func setWith(domain: DomainItem, qrImage: UIImage) {
        Task {
            let avatarImage = await appContext.imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: nil)
            await MainActor.run {
                setWith(avatarImage: avatarImage)
            }
        }
        setWith(qrImage: qrImage)
        qrContainerView.layer.cornerRadius = 2
    }
    
    func setWith(domain: DomainItem, avatarImage: UIImage, qrImage: UIImage) {
        setWith(avatarImage: avatarImage)
        setWith(qrImage: qrImage)
        qrContainerView.layer.cornerRadius = 2
    }
    
    func prepareForExport() {
        contentView.layer.cornerRadius = 0
        avatarImageView.layer.cornerRadius = 0
        avatarCoverView.layer.cornerRadius = 0
        qrContainerView.layer.cornerRadius = 8
        qrCodeOffsetConstraints.forEach { constraint in
            constraint.constant = 3
        }
    }
    
}

// MARK: - Private methods
private extension UDDomainSharingWatchCardView {
    func setWith(qrImage: UIImage) {
        qrCodeImageView.image = qrImage.transparentImage()
    }
    
    func setWith(avatarImage: UIImage?) {
        avatarImageView.image = avatarImage ?? .domainSharePlaceholder
        avatarCoverView.isHidden = avatarImage == .domainSharePlaceholder
    }
}

// MARK: - Setup methods
private extension UDDomainSharingWatchCardView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        clipsToBounds = true
        contentView.clipsToBounds = true 
        contentView.layer.cornerRadius = 12
        contentView.backgroundColor = .systemBackground
        avatarImageView.layer.cornerRadius = 8
        avatarCoverView.layer.cornerRadius = avatarImageView.layer.cornerRadius
        bgGradientView.gradientDirection = .topRightToBottomLeft
        bgGradientView.gradientColors = [.white.withAlphaComponent(0.12), .white.withAlphaComponent(0.001)]
    }
}
