//
//  TextButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.04.2022.
//

import UIKit

class TextButton: BaseButton {
    
    var isSuccess: Bool = false {
        didSet { self.tintColor = self.textColor }
    }
    
    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .clear }
    override var backgroundDisabledColor: UIColor { .clear }
    override var textColor: UIColor { isSuccess ? .foregroundSuccess : .foregroundAccent }
    override var textHighlightedColor: UIColor { isSuccess ? .foregroundSuccess : .foregroundAccentMuted }
    override var textDisabledColor: UIColor { isSuccess ? .foregroundSuccess : .foregroundAccentMuted }
    override var fontWeight: UIFont.Weight { .medium }
    
}
