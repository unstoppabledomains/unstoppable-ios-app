//
//  UITextField.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import UIKit

extension UITextField: ObjectWithAttributedString {
    var attributedString: NSAttributedString! {
        get {
            self.attributedText
        }
        set {
            self.attributedText = newValue
        }
    }
    
    var stringColor: UIColor? { textColor }
    var textFont: UIFont? { font }
}

