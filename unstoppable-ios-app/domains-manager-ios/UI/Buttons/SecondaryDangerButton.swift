//
//  SecondaryDangerButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.05.2022.
//

import UIKit

final class SecondaryDangerButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .backgroundSubtle }
    override var backgroundDisabledColor: UIColor { .clear }
    
    override var textColor: UIColor { .foregroundDanger }
    override var textHighlightedColor: UIColor { .foregroundDanger }
    override var textDisabledColor: UIColor { .foregroundDangerMuted }
    override var fontWeight: UIFont.Weight { .semibold }
    
}
