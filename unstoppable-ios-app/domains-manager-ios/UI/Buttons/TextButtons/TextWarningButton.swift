//
//  TextWarningButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.08.2022.
//

import UIKit

final class TextWarningButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .clear }
    override var backgroundDisabledColor: UIColor { .clear }
    override var textColor: UIColor { .foregroundWarning }
    override var textHighlightedColor: UIColor { .foregroundWarningMuted }
    override var textDisabledColor: UIColor { .foregroundWarningMuted }
    override var fontWeight: UIFont.Weight { .medium }
    
}
