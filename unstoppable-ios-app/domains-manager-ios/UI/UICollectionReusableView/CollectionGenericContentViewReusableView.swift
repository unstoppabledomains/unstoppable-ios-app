//
//  CollectionGenericItemReusableView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import UIKit

class CollectionGenericContentViewReusableView<View: UIView>: UICollectionReusableView {

    var isHorizontallyCentered: Bool { true }
    private(set) var contentViewCenterYConstraint: NSLayoutConstraint!
    let contentView = View()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    func additionalSetup() { }
}

// MARK: - Setup methods
private extension CollectionGenericContentViewReusableView {
    func setup() {
        setupItem()
        additionalSetup()
    }
    
    func setupItem() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        
        if isHorizontallyCentered {
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }
        contentViewCenterYConstraint = contentView.centerYAnchor.constraint(equalTo: centerYAnchor)
        contentViewCenterYConstraint.isActive = true
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    }
}


