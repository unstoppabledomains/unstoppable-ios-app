//
//  DomainsCollectionTitleDomainInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.12.2022.
//

import UIKit

final class DomainsCollectionTitleDomainInfoView: UIView {
    
    private var avatarImageView: UIImageView!
    private var domainNameLabel: UILabel!
    private let height: CGFloat = 24
    private var domainName: String = ""
    
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

        let labelWidth = domainName.width(withConstrainedHeight: height,
                                          font: domainNameLabel.font)
        avatarImageView.frame.origin.x = 0
        domainNameLabel.frame.origin.x = avatarImageView.frame.maxX + 8
        domainNameLabel.frame.size.width = labelWidth
        self.bounds.size = CGSize(width: domainNameLabel.frame.maxX,
                                  height: height)
    }
    
}

// MARK: - Open methods
extension DomainsCollectionTitleDomainInfoView {
    func setWith(domain: DomainDisplayInfo) {
        domainName = domain.name
        domainNameLabel.setAttributedTextWith(text: domain.name,
                                              font: .currentFont(withSize: 16, weight: .bold),
                                              textColor: .foregroundDefault)
        setNeedsLayout()
        Task {
            avatarImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domain,
                                                                                                         size: .default),
                                                                                   downsampleDescription: nil)
            let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain,
                                                                                                   size: .default),
                                                                       downsampleDescription: .icon)
            avatarImageView.image = image
        }
    }
}

// MARK: - Setup methods
private extension DomainsCollectionTitleDomainInfoView {
    func setup() {
        setupAvatarImageView()
        setupDomainNameLabel()
    }
    
    func setupAvatarImageView() {
        let avatarSize: CGFloat = 20
        avatarImageView = UIImageView(frame: .init(origin: .init(x: 0,
                                                                 y: 2),
                                                   size: .init(width: avatarSize,
                                                               height: avatarSize)))
        avatarImageView.layer.cornerRadius = avatarSize / 2
        avatarImageView.clipsToBounds = true
        addSubview(avatarImageView)
    }
    
    func setupDomainNameLabel() {
        domainNameLabel = UILabel(frame: .init(origin: .zero,
                                               size: .init(width: 0,
                                                           height: height)))
        addSubview(domainNameLabel)
    }
}
