//
//  SubheadTertiaryButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import UIKit

final class SubheadTertiaryButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .clear }
    override var backgroundDisabledColor: UIColor { .clear }
    override var textColor: UIColor { .foregroundSecondary }
    override var textHighlightedColor: UIColor { .foregroundMuted }
    override var textDisabledColor: UIColor { .foregroundSubtle }
    override var fontWeight: UIFont.Weight { .medium }
    override var fontSize: CGFloat { 14 }
    
}
