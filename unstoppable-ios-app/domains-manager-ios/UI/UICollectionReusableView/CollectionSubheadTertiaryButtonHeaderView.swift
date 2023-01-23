//
//  CollectionSubheadTertiaryButtonHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2022.
//

import UIKit

class CollectionSubheadTertiaryButtonHeaderView: CollectionGenericContentViewReusableView<SubheadTertiaryButton> {
    
    override var isHorizontallyCentered: Bool { false }
    var headerButtonPressedCallback: EmptyCallback?
    var buttonTitle: String { "" }
    
    override func additionalSetup() {
        contentView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        contentView.imageLayout = .trailing
        contentView.addTarget(self, action: #selector(didPressHeaderButton), for: .touchUpInside)
        contentViewCenterYConstraint.constant = -7
    }
    
    func setHeader() {
        contentView.isHidden = false
        let header = buttonTitle
        contentView.setTitle(header, image: .infoIcon16)
    }
    
}

// MARK: - Private methods
private extension CollectionSubheadTertiaryButtonHeaderView {
    @objc func didPressHeaderButton() {
        headerButtonPressedCallback?()
    }
}

