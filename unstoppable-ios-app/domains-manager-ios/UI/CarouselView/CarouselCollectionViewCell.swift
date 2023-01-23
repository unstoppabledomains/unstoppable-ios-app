//
//  CarouselCollectionViewCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.10.2022.
//

import UIKit

final class CarouselCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    static func widthFor(carouselItem: CarouselViewItem) -> CGFloat {
        let sideOffset: CGFloat = 12
        let uiElementsSpacing: CGFloat = 8
        let iconWidth: CGFloat = 20
        let textSize: CGFloat = carouselItem.text.width(withConstrainedHeight: 32,
                                                        font: .currentFont(withSize: 16, weight: .medium))
        
        return iconWidth + textSize + uiElementsSpacing + (sideOffset * 2)
    }

}

// MARK: - Open methods
extension CarouselCollectionViewCell {
    
    func set(carouselItem: CarouselViewItem) {
        iconImageView.image = carouselItem.icon
        textLabel.text = carouselItem.text
        textLabel.setAttributedTextWith(text: carouselItem.text,
                                        font: .currentFont(withSize: 16, weight: .medium),
                                        textColor: .foregroundSecondary)
    }
    
}
