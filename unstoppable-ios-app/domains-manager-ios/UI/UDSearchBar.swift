//
//  UDSearchBar.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2022.
//

import UIKit

final class UDSearchBar: UISearchBar {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
}

// MARK: - Setup methods
private extension UDSearchBar {
    func setup() {
        applyUDStyle()
    }
}
