//
//  CarouselCollectionViewCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.10.2022.
//

import UIKit

final class CarouselCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var iconImageView: KeepingAnimationImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var imageSizeConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentLeftOffsetConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    static func widthFor(carouselItem: CarouselViewItem,
                         sideOffset: CGFloat,
                         style: CarouselCollectionViewCell.Style) -> CGFloat {
        let sideOffset: CGFloat = sideOffset
        let uiElementsSpacing: CGFloat = 8
        let iconWidth: CGFloat = style.imageSize
        let textSize: CGFloat = carouselItem.text.width(withConstrainedHeight: 32,
                                                        font: .currentFont(withSize: style.fontSize, weight: .medium))
        
        return iconWidth + textSize + uiElementsSpacing + (sideOffset * 2)
    }

}

// MARK: - Open methods
extension CarouselCollectionViewCell {
    
    func set(carouselItem: CarouselViewItem,
             sideOffset: CGFloat,
             style: Style) {
        contentLeftOffsetConstraint.constant = sideOffset
        iconImageView.image = carouselItem.icon
        textLabel.setAttributedTextWith(text: carouselItem.text,
                                        font: .currentFont(withSize: style.fontSize, weight: .medium),
                                        textColor: carouselItem.tintColor)
        iconImageView.tintColor = carouselItem.tintColor
        containerView.backgroundColor = carouselItem.backgroundColor
        setStyle(style)
        if carouselItem.isRotating {
            iconImageView.runUpdatingRecordsAnimation()
        } else {
            iconImageView.stopUpdatingRecordsAnimation()
        }
    }
    
}

// MARK: - Private methods
private extension CarouselCollectionViewCell {
    func setStyle(_ style: Style) {
        imageSizeConstraint.constant = style.imageSize
    }
}

extension CarouselCollectionViewCell {
    enum Style {
        case `default`, small
        
        var imageSize: CGFloat {
            switch self {
            case .default:
                return 20
            case .small:
                return 12
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .default:
                return 16
            case .small:
                return 12
            }
        }
    }
}
