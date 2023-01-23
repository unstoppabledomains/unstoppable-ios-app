//
//  TableViewSelectionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.04.2022.
//

import UIKit

final class TableViewSelectionCell: UITableViewCell {
    
    static let Height: CGFloat = 70

    @IBOutlet private weak var iconContainerView: IconBorderedContainerView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var iconImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!
    @IBOutlet private weak var greyOutView: UIView!
    
    private var backgroundContainerView: UIView!
    private var secondaryTextStyle: SecondaryTextStyle = .blue
    var isSelectable: Bool = true

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        backgroundColor = .backgroundOverlay
        addBackgroundContainerView()
        greyOutView.alpha = 0.7
        greyOutView.isHidden = true
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard isSelectable else { return }
        super.setHighlighted(highlighted, animated: animated)

        backgroundContainerView.backgroundColor = highlighted ? UIColor.backgroundSubtle : self.backgroundColor
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setHighlighted(true, animated: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setHighlighted(false, animated: true)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        setHighlighted(false, animated: true)
    }

}

// MARK: - Open methods
extension TableViewSelectionCell {
    func setWith(icon: UIImage,
                 iconTintColor: UIColor? = nil,
                 iconStyle: IconStyle,
                 iconFillMode: IconFillMode = .center,
                 text: String,
                 secondaryText: String?) {
        iconContainerView.backgroundColor = iconStyle.backgroundColor
        iconImageView.image = icon
        if let tintColor = iconTintColor {
            iconImageView.tintColor = tintColor
        }
        primaryLabel.setAttributedTextWith(text: text,
                                           font: .currentFont(withSize: 16, weight: .medium),
                                           textColor: .foregroundDefault,
                                           lineHeight: 24)
        updateSecondaryText(secondaryText)
        secondaryLabel.isHidden = secondaryText == nil
        iconImageViewLeadingConstraint.constant = iconFillMode.conentOffset
    }
    
    func setSecondaryText(_ text: String) {
        secondaryLabel.isHidden = false
        updateSecondaryText(text)
    }
    
    func setGreyedOut(_ isGreyedOut: Bool) {
        greyOutView.isHidden = !isGreyedOut
        isSelectable = !isGreyedOut
        isUserInteractionEnabled = !isGreyedOut
        setSecondaryTextStyle(secondaryTextStyle)
    }
    
    func setSecondaryTextStyle(_ secondaryTextStyle: SecondaryTextStyle) {
        self.secondaryTextStyle = secondaryTextStyle
        if let secondaryText = self.secondaryLabel.attributedText?.string {
            updateSecondaryText(secondaryText)
        }
    }
}

// MARK: - Private methods
private extension TableViewSelectionCell {
    func updateSecondaryText(_ text: String?) {
        secondaryLabel.setAttributedTextWith(text: text ?? "",
                                             font: secondaryTextStyle.font,
                                             textColor: isSelectable ? secondaryTextStyle.color : .foregroundDefault,
                                             lineHeight: 20)
    }
    
    func addBackgroundContainerView() {
        backgroundContainerView = UIView()
        backgroundContainerView.backgroundColor = self.backgroundColor
        backgroundContainerView.embedInSuperView(self, constraints: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
        backgroundContainerView.layer.cornerRadius = 8
        self.insertSubview(backgroundContainerView, at: 0)
    }
}

// MARK: - SecondaryTextStyle
extension TableViewSelectionCell {
    enum IconStyle {
        case accent, grey
        
        var backgroundColor: UIColor {
            switch self {
            case .accent:
                return .backgroundAccentEmphasis
            case .grey:
                return .backgroundMuted2
            }
        }
    }
    
    enum IconFillMode {
        case center, fill
        
        var conentOffset: CGFloat {
            switch self {
            case .center:
                return 10
            case .fill:
                return 0
            }
        }
    }
    
    enum SecondaryTextStyle {
        case blue, grey
        
        var color: UIColor {
            switch self {
            case .blue: return .foregroundAccent
            case .grey: return .foregroundSecondary
            }
        }
        
        var font: UIFont {
            switch self {
            case .blue: return .currentFont(withSize: 14, weight: .medium)
            case .grey: return .currentFont(withSize: 14, weight: .regular)
            }
        }
    }
}
