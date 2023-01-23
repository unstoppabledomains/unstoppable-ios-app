//
//  CollectionDashesHeaderReusableView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.10.2022.
//

import UIKit

final class CollectionDashesHeaderReusableView: CollectionGenericContentViewReusableView<DashesView> {
    
    class var reuseIdentifier: String { "CollectionDashesHeaderReusableView" }
    
    static let Height: CGFloat = 25
    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var alignment: AlignmentPosition = .top
    
    override func additionalSetup() {
        contentView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentViewCenterYConstraint.isActive = false
        
        bottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        topConstraint = contentView.topAnchor.constraint(equalTo: topAnchor)
        
        alignTop()
    }
    
    func setAlignmentPosition(_ alignment: AlignmentPosition) {
        self.alignment = alignment
        
        switch alignment {
        case .top:
            alignTop()
        case .bottom:
            alignBottom()
        }
    }
}

// MARK: - Private methods
private extension CollectionDashesHeaderReusableView {
    func alignBottom() {
        topConstraint?.isActive = false
        bottomConstraint?.isActive = true
    }
    
    func alignTop() {
        bottomConstraint?.isActive = false
        topConstraint?.isActive = true
    }
}

extension CollectionDashesHeaderReusableView {
    enum AlignmentPosition {
        case top, bottom
    }
}
