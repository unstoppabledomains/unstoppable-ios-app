//
//  File.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

final class BorderedView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        layer.borderColor = UIColor.borderMuted.cgColor
    }
}

// MARK: - Setup methods
private extension BorderedView {
    func setup() {
        clipsToBounds = true
        backgroundColor = .backgroundOverlay
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.borderMuted.cgColor
    }
}
