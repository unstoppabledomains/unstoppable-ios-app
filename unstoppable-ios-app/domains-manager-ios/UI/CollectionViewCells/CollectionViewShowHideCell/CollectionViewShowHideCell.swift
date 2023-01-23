//
//  CollectionViewShowHideCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.09.2022.
//

import UIKit

final class CollectionViewShowHideCell: BaseListCollectionViewCell {
    
    @IBOutlet private weak var chevronImageView: UIImageView!
    @IBOutlet private weak var showHideLabel: UILabel!
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    
    override var containerColor: UIColor { style.backgroundColor }
    private var style: Style = .default
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

}

// MARK: - Open methods
extension CollectionViewShowHideCell {
    func setWith(text: String,
                 direction: ArrowDirection,
                 style: Style = .default,
                 height: CGFloat) {
        heightConstraint.constant = height
        chevronImageView.image = direction.icon
        chevronImageView.tintColor = style.textColor
        showHideLabel.setAttributedTextWith(text: text,
                                            font: .currentFont(withSize: 16, weight: .medium),
                                            textColor: style.textColor)
        self.style = style
        updateAppearance()
    }
}

// MARK: - Open methods
extension CollectionViewShowHideCell {
    enum ArrowDirection {
        case up, down
        
        var icon: UIImage {
            switch self {
            case .up:
                return .chevronUp
            case .down:
                return .chevronDown
            }
        }
    }
    
    enum Style {
        case `default`, clear
        
        var backgroundColor: UIColor {
            switch self {
            case .default:
                return .backgroundOverlay
            case .clear:
                return .clear
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .default:
                return .foregroundAccent
            case .clear:
                return .brandWhite
            }
        }
    }
}
