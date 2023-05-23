//
//  ChatSectionHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.05.2023.
//

import UIKit

final class ChatSectionHeaderView: CollectionGenericContentViewReusableView<UILabel> {
    
    static var reuseIdentifier = "ChatSectionHeaderView"
    static let Height: CGFloat = 32
    
    func setTitle(_ title: String) {
        contentView.setAttributedTextWith(text: title,
                                          font: .currentFont(withSize: 12, weight: .regular),
                                          textColor: .foregroundSecondary,
                                          alignment: .center,
                                          lineHeight: 16)
    }
    
    override func additionalSetup() {
        contentViewCenterYConstraint.isActive = false
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
    
}

