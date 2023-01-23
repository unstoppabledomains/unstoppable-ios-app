//
//  BorderedTableView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.04.2022.
//

import UIKit

final class BorderedTableView: UITableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        
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
private extension BorderedTableView {
    func setup() {
        clipsToBounds = true
        backgroundColor = .backgroundOverlay
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.borderMuted.cgColor
    }
}
