//
//  TextWhiteButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import UIKit

final class TextWhiteButton: BaseButton {
    
    var isSuccess: Bool = false {
        didSet { self.tintColor = self.textColor }
    }
    
    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .clear }
    override var backgroundDisabledColor: UIColor { .clear }
    override var textColor: UIColor { isSuccess ? .foregroundSuccess : .white.withAlphaComponent(0.56) }
    override var textHighlightedColor: UIColor { isSuccess ? .foregroundSuccess : .white.withAlphaComponent(0.32) }
    override var textDisabledColor: UIColor { isSuccess ? .foregroundSuccess : .white.withAlphaComponent(0.32) }
    override var fontWeight: UIFont.Weight { .medium }
    
}

