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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
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
}

// MARK: - Setup methods
private extension UnreadMessagesBadgeView {
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(greaterThanOrEqualToConstant: size).isActive = true
        heightAnchor.constraint(equalToConstant: size).isActive = true
        layer.cornerRadius = size / 2
        backgroundColor = .foregroundAccent
        
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
