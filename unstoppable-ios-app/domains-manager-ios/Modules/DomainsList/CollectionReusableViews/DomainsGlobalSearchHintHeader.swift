//
//  DomainsGlobalSearchHintHeader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.08.2023.
//

import UIKit

final class DomainsGlobalSearchHintHeader: CollectionGenericContentViewReusableView<UIStackView> {
    
    class var reuseIdentifier: String { "DomainsGlobalSearchHintHeader" }
//    override var isHorizontallyCentered: Bool { false }
    
    override func additionalSetup() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setAttributedTextWith(text: String.Constants.globalSearchHint.localized(),
                                    font: .currentFont(withSize: 14, weight: .medium),
                                    textColor: .foregroundSecondary,
                                    alignment: .left)
        label.numberOfLines = 2
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .foregroundSecondary
        imageView.image = .infoIcon16
        
        contentView.axis = .horizontal
        contentView.spacing = 8
        contentView.alignment = .center
        contentView.distribution = .fill
        
        
        contentView.addArrangedSubview(imageView)
        contentView.addArrangedSubview(label)
    }
    
}

// MARK: - Private methods
private extension DomainsGlobalSearchHintHeader {

}
