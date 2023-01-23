//
//  PasscodeButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.04.2022.
//

import UIKit

final class PasscodeButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { UIScreen.main.isCaptured ? .clear : .backgroundSubtle }
    override var backgroundDisabledColor: UIColor { .clear }
    
    override var textColor: UIColor { .foregroundDefault }
    override var textHighlightedColor: UIColor { .foregroundDefault }
    override var textDisabledColor: UIColor { .foregroundDefault }
    
    override var fontSize: CGFloat { 28 }
    override var fontWeight: UIFont.Weight { .medium }
    
    override var cornerRadius: CGFloat { 32 }
    
}
