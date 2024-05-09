//
//  ListItemView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import UIKit

final class ListItemView: UIControl, SelfNameable, NibInstantiateable {
    
    @IBOutlet var containerView: UIView!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var backgroundContainerView: UIView!
    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private var primaryLabel: UILabel!
    @IBOutlet private var secondaryLabel: UILabel!
    @IBOutlet private weak var secondaryBackgroundView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        baseInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        baseInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        backgroundContainerView.backgroundColor = .white.withAlphaComponent(0.08)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        backgroundContainerView.backgroundColor = .clear
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        backgroundContainerView.backgroundColor = .clear
    }
}

// MARK: - Open methods
extension ListItemView {
    func setWith(icon: UIImage, text: String, secondaryText: String? = nil, style: Style = .default) {
        iconImageView.image = icon
        iconImageView.tintColor = style.tintColor
        primaryLabel.setAttributedTextWith(text: text,
                                           font: .currentFont(withSize: 16, weight: .medium),
                                           textColor: style.tintColor)
        if let secondaryText = secondaryText {
            secondaryLabel.setAttributedTextWith(text: secondaryText,
                                                 font: .currentFont(withSize: 16, weight: .medium),
                                                 textColor: .white)
        }
        secondaryBackgroundView.isHidden = secondaryText == nil
    }
}

// MARK: - Private methods
private extension ListItemView {
    @objc func didTapSelf() {
        sendActions(for: .touchUpInside)
    }
}

// MARK: - Setup methods
private extension ListItemView {
    func baseInit() {
        backgroundColor = .clear
        commonViewInit()
        
        contentView.backgroundColor = .white.withAlphaComponent(0.16)
        contentView.layer.cornerRadius = 12
        backgroundContainerView.layer.cornerRadius = 8
        backgroundContainerView.backgroundColor = .clear
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSelf))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tap)
    }
}

extension ListItemView {
    enum Style {
        case `default`, dimmed
        
        var tintColor: UIColor {
            switch self {
            case .default:
                return .white
            case .dimmed:
                return .white.withAlphaComponent(0.32)
            }
        }
    }
}
