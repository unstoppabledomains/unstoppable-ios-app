//
//  EmptyCollectionReusableView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import Foundation

import UIKit

final class EmptyCollectionReusableView: UICollectionReusableView {
    
    static var reuseIdentifier = "EmptyCollectionReusableView"
    
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
private extension EmptyCollectionReusableView {
    func setup() {
        backgroundColor = .clear
    }
}
