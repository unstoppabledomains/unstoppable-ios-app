//
//  UILabel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.04.2022.
//

import UIKit

extension UILabel: ObjectWithAttributedString {
    var attributedString: NSAttributedString! {
        get {
            attributedText
        }
        set {
            attributedText = newValue
        }
    }
    
    var stringColor: UIColor? { textColor }
    var textFont: UIFont? { font }
}
