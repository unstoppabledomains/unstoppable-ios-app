//
//  DomainProfileTutorialItemPrivacyViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2022.
//

import UIKit

final class DomainProfileTutorialItemPrivacyViewController: UIViewController {
    
    var style: Style = .large
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
}

// MARK: - Setup methods
private extension DomainProfileTutorialItemPrivacyViewController {
    func setup() {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setAttributedTextWith(text: String.Constants.domainProfileAccessInfoTitle.localized(),
                                         font: .currentFont(withSize: style.titleFontSize, weight: .bold),
                                         textColor: .foregroundDefault,
                                         alignment: .center,
                                         lineHeight: 40)
        titleLabel.numberOfLines = 0
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.setAttributedTextWith(text: String.Constants.domainProfileAccessInfoDescription.localized(),
                                            font: .currentFont(withSize: 16, weight: .regular),
                                            textColor: .foregroundSecondary,
                                            alignment: .center,
                                            lineHeight: 24)
        subtitleLabel.numberOfLines = 0
        
        let bottomContentStack: UIStackView
        
        switch style {
        case .pullUp, .large:
            let spacerView = UIView()
            spacerView.backgroundColor = .clear
            spacerView.translatesAutoresizingMaskIntoConstraints = false
            spacerView.heightAnchor.constraint(equalToConstant: 32).isActive = true
            bottomContentStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, spacerView])
        case .pullUpSingle:
            bottomContentStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        }
        
        bottomContentStack.axis = .vertical
        bottomContentStack.spacing = style == .large ? 16 : 8
        bottomContentStack.alignment = .fill
        bottomContentStack.translatesAutoresizingMaskIntoConstraints = false
        
        let image = style.illustrationImage
        let imageView = UIImageView(image: image)
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: image.size.width / image.size.height).isActive = true
        
        
        let contentStackView = UIStackView(arrangedSubviews: [imageView, bottomContentStack])
        contentStackView.axis = .vertical
        contentStackView.spacing = 0
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        
        view.addSubview(contentStackView)
        contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        contentStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}

extension DomainProfileTutorialItemPrivacyViewController {
    enum Style {
        case large, pullUp, pullUpSingle
        
        var titleFontSize: CGFloat {
            switch self {
            case .large:
                return 32
            case .pullUp, .pullUpSingle:
                return 22
            }
        }
        
        var illustrationImage: UIImage {
            switch self {
            case .large:
                return deviceSize == .i4Inch ? .profileAccessIllustrationLargeiPhoneSE : .profileAccessIllustrationLarge
            case .pullUp, .pullUpSingle:
                return .profileAccessIllustration
            }
        }
    }
}
