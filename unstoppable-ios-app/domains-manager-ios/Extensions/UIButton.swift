//
//  UIButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.04.2022.
//

import UIKit

extension UIButton: ObjectWithAttributedString {
    var attributedString: NSAttributedString! {
        get {
            attributedTitle(for: .normal)
        }
        set {
            setAttributedTitle(newValue, for: .normal)
        }
    }
    
    var stringColor: UIColor? {
        titleColor(for: .normal)
    }
    
    var textFont: UIFont? {
        titleLabel?.font
    }
    
    var textAlignment: NSTextAlignment {
        titleLabel?.textAlignment ?? .left
    }
    
    
}
