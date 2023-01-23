//
//  UIMenuBridgeViewControllerItemCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2022.
//

import UIKit

final class UIMenuBridgeViewControllerItemCell: UITableViewCell {

    @IBOutlet private weak var selectedIndicatorLabel: UILabel!
    @IBOutlet private weak var itemTextLabel: UILabel!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var iconViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var disabledCoverView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        separatorInset = .zero
        selectedIndicatorLabel.font = UIFont(name: "SFProText-Regular", size: 14)
        itemTextLabel.font = UIFont(name: "SFProText-Regular", size: 17)
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = .systemGray5.withAlphaComponent(0.4)
        selectedBackgroundView = backgroundView
    }

    func setWith(text: String,
                 icon: UIImage?,
                 isSelected: Bool,
                 style: Style = .default,
                 isEnabled: Bool) {
        itemTextLabel.text = text
        iconView.image = icon
        selectedIndicatorLabel.text = isSelected ? "\u{2713}" : ""
        if let icon = icon {
            iconViewWidthConstraint.constant = min(icon.size.width, 24)
        }
        itemTextLabel.textColor = style.tintColor
        iconView.tintColor = style.tintColor
        disabledCoverView.isHidden = isEnabled
        isUserInteractionEnabled = isEnabled
    }
    
}

extension UIMenuBridgeViewControllerItemCell {
    enum Style {
        case `default`, destructive
        
        var tintColor: UIColor {
            switch self {
            case .default:
                return .label
            case .destructive:
                return .systemRed
            }
        }
    }
}
