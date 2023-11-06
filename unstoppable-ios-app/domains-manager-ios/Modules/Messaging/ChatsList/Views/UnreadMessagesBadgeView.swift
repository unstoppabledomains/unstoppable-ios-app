//
//  UnreadMessagesBadgeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import UIKit

final class UnreadMessagesBadgeView: UIView {
    
    private var size: CGFloat = 16
    private var counterLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
}

// MARK: - Open methods
extension UnreadMessagesBadgeView {
    func setUnreadMessagesCount(_ unreadMessagesCount: Int) {
        isHidden = unreadMessagesCount == 0
        counterLabel.setAttributedTextWith(text: String(unreadMessagesCount),
                                           font: .currentFont(withSize: 11, weight: .semibold),
                                           textColor: .white,
                                           alignment: .center)
    }
    
    func setStyle(_ style: Style) {
        backgroundColor = style.backgroundColor
    }
    
    func setCounterLabel(hidden: Bool) {
        counterLabel.isHidden = hidden
    }
    
    func setConstraints(size: CGFloat = 16) {
        self.size = size
        layer.cornerRadius = size / 2

        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(greaterThanOrEqualToConstant: size).isActive = true
        heightAnchor.constraint(equalToConstant: size).isActive = true
        
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([counterLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     counterLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                                     counterLabel.heightAnchor.constraint(equalToConstant: size),
                                     counterLabel.widthAnchor.constraint(equalToConstant: size)])
    }
}

// MARK: - Setup methods
private extension UnreadMessagesBadgeView {
    func setup() {
        layer.cornerRadius = size / 2
        backgroundColor = Style.blue.backgroundColor
        setupCounterLabel()
    }
    
    func setupCounterLabel() {
        counterLabel = UILabel()
        addSubview(counterLabel)
    }
}

// MARK: - Open methods
extension UnreadMessagesBadgeView {
    enum Style {
        case blue, black
        
        var backgroundColor: UIColor {
            switch self {
            case .blue:
                return .foregroundAccent
            case .black:
                return .black
            }
        }
    }
}
