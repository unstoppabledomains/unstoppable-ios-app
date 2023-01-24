//
//  UDDomainCardView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

final class UDDomainCardView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var coverView: UIView!
    @IBOutlet private weak var shadowView: UIView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var tldLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async { [weak self] in
            self?.setupShadowView()
        }
    }
}

// MARK: - Open methods
extension UDDomainCardView {
    func setWith(domainItem: DomainDisplayInfo) {
        if domainItem.pfpSource != .none,
           let image = appContext.imageLoadingService.getStoredImage(for: .domain(domainItem)) {
            setWith(domainName: domainItem.name, avatarImage: image)
        } else {
            setWith(domainName: domainItem.name, avatarImage: nil)
            Task {
                let image = await appContext.imageLoadingService.loadImage(from: .domain(domainItem),
                                                                           downsampleDescription: nil)
                setWith(domainName: domainItem.name, avatarImage: image)
            }
        }
    }
    
    @MainActor
    func setWith(domainName: String, avatarImage: UIImage?) {
        let name = domainName.getBelowTld() ?? ""
        let domain = domainName.getTldName() ?? ""
        
        nameLabel.setAttributedTextWith(text: name.uppercased(),
                                        font: .helveticaNeueCustom(size: 44),
                                        letterSpacing: 0,
                                        textColor: .foregroundOnEmphasis,
                                        lineHeight: 44,
                                        lineBreakMode: .byTruncatingTail)
        tldLabel.setAttributedTextWith(text: String.dotSeparator + domain.uppercased(),
                                       font: .helveticaNeueCustom(size: 36),
                                       letterSpacing: 0,
                                       textColor: .clear,
                                       lineHeight: 36,
                                       lineBreakMode: .byTruncatingTail,
                                       strokeColor: .foregroundOnEmphasis,
                                       strokeWidth: 3)
        
        coverView.isHidden = avatarImage == nil
        avatarImageView.image = avatarImage ?? .domainSharePlaceholder
    }
}

// MARK: - Setup methods
private extension UDDomainCardView {
    func setup() {
        backgroundColor = .clear
        clipsToBounds = false
        commonViewInit()
        setupContainer()
        setupShadowView()
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = Constants.domainNameMinimumScaleFactor
        nameLabel.setAttributedTextWith(text: "")
        tldLabel.setAttributedTextWith(text: "")
        avatarImageView.image = .domainSharePlaceholder
    }
    
    func setupContainer() {
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 12
        contentView.backgroundColor = .systemBackground
    }
    
    func setupShadowView() {
        shadowView.applyFigmaShadow(style: .large)
        nameLabel.applyFigmaShadow(style: .xSmall)
        tldLabel.applyFigmaShadow(style: .xSmall)
    }
}
