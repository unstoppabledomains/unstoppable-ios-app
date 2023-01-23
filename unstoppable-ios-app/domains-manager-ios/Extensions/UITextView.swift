//
//  UITextView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.04.2022.
//

import UIKit

extension UITextView: ObjectWithAttributedString {
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
