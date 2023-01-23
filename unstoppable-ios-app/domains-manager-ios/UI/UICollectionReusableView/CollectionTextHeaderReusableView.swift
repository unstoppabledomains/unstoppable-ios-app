//
//  CollectionLabelReusableView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import UIKit

class CollectionTextHeaderReusableView: CollectionGenericContentViewReusableView<UILabel> {

    class var reuseIdentifier: String { "CollectionTextHeaderReusableView" }
    static let Height: CGFloat = 52

    func setHeader(_ header: String) {
        contentView.setAttributedTextWith(text: header,
                                          font: .currentFont(withSize: 14, weight: .medium),
                                          textColor: .foregroundSecondary)
    }

}
