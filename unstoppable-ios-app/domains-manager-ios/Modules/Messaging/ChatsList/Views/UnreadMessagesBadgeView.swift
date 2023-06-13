//
//  UnreadMessagesBadgeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import UIKit

final class UnreadMessagesBadgeView: UIView {
    
    private let size: CGFloat = 16
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
}

// MARK: - Setup methods
private extension UnreadMessagesBadgeView {
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(greaterThanOrEqualToConstant: size).isActive = true
        heightAnchor.constraint(equalToConstant: size).isActive = true
        layer.cornerRadius = size / 2
        backgroundColor = Style.blue.backgroundColor
        
        setupCounterLabel()
    }
    
    func setupCounterLabel() {
        counterLabel = UILabel()
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(counterLabel)
        
        NSLayoutConstraint.activate([counterLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     counterLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                                     counterLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)])
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
