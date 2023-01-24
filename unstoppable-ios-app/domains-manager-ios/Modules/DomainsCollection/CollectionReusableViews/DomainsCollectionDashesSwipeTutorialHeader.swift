//
//  DomainsCollectionDashesSwipeTutorialHeader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.12.2022.
//

import UIKit

final class DomainsCollectionDashesSwipeTutorialHeader: CollectionGenericContentViewReusableView<UIStackView> {
    
    class var reuseIdentifier: String { "DomainsCollectionDashesSwipeTutorialHeader" }
            
    override func additionalSetup() {
        contentView.axis = .horizontal
        contentView.alignment = .center
        contentView.distribution = .fill
        contentView.spacing = 8
        
        let textLabel = buildTutorialDescription()
        let leftDashesView = buildDashesView()
        let rightDashesView = buildDashesView()
        
        contentView.addArrangedSubview(leftDashesView)
        contentView.addArrangedSubview(textLabel)
        contentView.addArrangedSubview(rightDashesView)
        
        leftDashesView.widthAnchor.constraint(equalTo: rightDashesView.widthAnchor).isActive = true
    }
    
}
 
// MARK: - Private methods
private extension DomainsCollectionDashesSwipeTutorialHeader {
    func buildDashesView() -> DashesView {
        let dashesView = DashesView()
        dashesView.translatesAutoresizingMaskIntoConstraints = false
        dashesView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        dashesView.setConfiguration(.domainsCollection)
        
        return dashesView
    }
    
    func buildTutorialDescription() -> UIView {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setAttributedTextWith(text: String.Constants.domainCardSwipeToDetails.localized(),
                                    font: .currentFont(withSize: 12, weight: .medium),
                                    textColor: .foregroundMuted,
                                    alignment: .center)
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .foregroundMuted
        imageView.image = .chevronUp
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .fill
        stack.distribution = .fill
        stack.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        return stack
    }
}
