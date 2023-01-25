//
//  UDSegmentedControl.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.01.2023.
//

import UIKit

final class UDSegmentedControl: UISegmentedControl {
    
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
private extension UDSegmentedControl {
    func setup() {
        setTitleTextAttributes([.font: UIFont.currentFont(withSize: 16, weight: .semibold)], for: .normal)
    }
}
