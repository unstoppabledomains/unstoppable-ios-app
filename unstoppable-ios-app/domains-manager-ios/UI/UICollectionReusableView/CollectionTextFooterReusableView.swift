//
//  CollectionTextFooterReusableView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.11.2022.
//

import UIKit

class CollectionTextFooterReusableView: CollectionGenericContentViewReusableView<UILabel> {
    
    class var reuseIdentifier: String { "CollectionTextFooterReusableView" }
    static let Height: CGFloat = 52
    static let font: UIFont = .currentFont(withSize: 14, weight: .regular)
    
    func setFooter(_ footer: String, textColor: UIColor = .foregroundSecondary) {
        contentView.numberOfLines = 0
        contentView.setAttributedTextWith(text: footer,
                                          font: Self.font,
                                          textColor: textColor)
    }
    
}
