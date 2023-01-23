//
//  TextBlackButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

final class TextBlackButton: BaseButton {

    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .clear }
    override var backgroundDisabledColor: UIColor { .clear }
    override var textColor: UIColor { .foregroundDefault }
    override var textHighlightedColor: UIColor { .foregroundMuted }
    override var textDisabledColor: UIColor { .foregroundMuted }
    override var fontWeight: UIFont.Weight { .medium }
    
}
