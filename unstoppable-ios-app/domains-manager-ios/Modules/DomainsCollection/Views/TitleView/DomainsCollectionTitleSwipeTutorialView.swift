//
//  DomainsCollectionTitleSwipeTutorialView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.12.2022.
//

import UIKit

final class DomainsCollectionTitleSwipeTutorialView: UIView {
    
    private var imageView: UIImageView!
    private var textLabel: UILabel!
    private let height: CGFloat = 16

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

        imageView.frame.origin.x = 0
        textLabel.frame.origin.x = imageView.frame.maxX + 4
        self.bounds.size = CGSize(width: textLabel.frame.maxX,
                                  height: height)
    }
    
}

// MARK: - Setup methods
private extension DomainsCollectionTitleSwipeTutorialView {
    func setup() {
        setupAvatarImageView()
        setupDomainNameLabel()
    }
    
    func setupAvatarImageView() {
        imageView = UIImageView(frame: .init(origin: .zero,
                                             size: .init(width: height,
                                                         height: height)))
        imageView.tintColor = .foregroundMuted
        imageView.image = .chevronDown
        imageView.clipsToBounds = true
        addSubview(imageView)
    }
    
    func setupDomainNameLabel() {
        let tutorialText = String.Constants.domainCardSwipeToCard.localized()
        let font: UIFont = .currentFont(withSize: 12, weight: .medium)
        let labelWidth = tutorialText.width(withConstrainedHeight: height,
                                            font: font)
        textLabel = UILabel(frame: .init(origin: .zero,
                                         size: .init(width: labelWidth,
                                                     height: height)))
        textLabel.setAttributedTextWith(text: tutorialText,
                                        font: font,
                                        textColor: .foregroundMuted)
        addSubview(textLabel)
    }
}



