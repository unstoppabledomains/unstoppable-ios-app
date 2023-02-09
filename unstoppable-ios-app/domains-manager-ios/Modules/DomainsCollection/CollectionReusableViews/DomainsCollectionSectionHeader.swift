//
//  DomainsCollectionSectionHeader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.12.2022.
//

import UIKit

final class DomainsCollectionSectionHeader: CollectionGenericContentViewReusableView<UILabel> {
    
    static let reuseIdentifier = "DomainsCollectionSectionHeader"
    static let height: CGFloat = 24
    
    func setHeader(_ header: String) {
        contentView.setAttributedTextWith(text: header,
                                          font: .currentFont(withSize: 20, weight: .bold),
                                          textColor: .foregroundDefault)
    }
    
}
