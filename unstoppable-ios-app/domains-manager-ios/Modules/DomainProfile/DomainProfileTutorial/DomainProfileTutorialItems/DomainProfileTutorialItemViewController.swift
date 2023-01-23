//
//  DomainProfileTutorialItemViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2022.
//

import UIKit

final class DomainProfileTutorialItemWeb3ViewController: UIViewController {
    
    var style: Style = .large
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
}

// MARK: - Setup methods
private extension DomainProfileTutorialItemWeb3ViewController {
    func setup() {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setAttributedTextWith(text: style.title,
                                         font: .currentFont(withSize: style.titleFontSize, weight: .bold),
                                         textColor: .foregroundDefault,
                                         alignment: .center,
                                         lineHeight: 40)
        titleLabel.numberOfLines = 0
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.setAttributedTextWith(text: String.Constants.domainProfileInfoDescription.localized(),
                                            font: .currentFont(withSize: deviceSize == .i4Inch ? 14 : 16, weight: .regular),
                                            textColor: .foregroundSecondary,
                                            alignment: .center,
                                            lineHeight: 24)
        subtitleLabel.numberOfLines = 0
        
        let carouselView = CarouselView()
        carouselView.translatesAutoresizingMaskIntoConstraints = false
        carouselView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        carouselView.set(data: UDCarouselFeature.ProfileInfoFeatures)
        
        let labelsStack = createVerticalStackView(subviews: [titleLabel, subtitleLabel])
        labelsStack.spacing = style == .large ? 16 : 8

        let bottomContentStack = createVerticalStackView(subviews: [labelsStack, carouselView])
        bottomContentStack.spacing = 16
        
        let image = style.illustrationImage
        let imageView = UIImageView(image: image)
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: image.size.width / image.size.height).isActive = true
        
        
        let contentStackView = createVerticalStackView(subviews: [imageView, bottomContentStack])
        
        view.addSubview(contentStackView)
        contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        contentStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    private func createVerticalStackView(subviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
}

extension DomainProfileTutorialItemWeb3ViewController {
    enum Style {
        case large, pullUp
        
        var title: String {
            switch self {
            case .large:
                return String.Constants.domainProfileCreateInfoTitle.localized()
            case .pullUp:
                return String.Constants.domainProfileInfoTitle.localized()
            }
        }
        
        var titleFontSize: CGFloat {
            switch self {
            case .large:
                return 32
            case .pullUp:
                return 22
            }
        }
        
        var illustrationImage: UIImage {
            switch self {
            case .large:
                return deviceSize == .i4Inch ? .web3ProfileIllustrationLargeiPhoneSE : .web3ProfileIllustrationLarge
            case .pullUp:
                return .web3ProfileIllustration
            }
        }
    }
}
