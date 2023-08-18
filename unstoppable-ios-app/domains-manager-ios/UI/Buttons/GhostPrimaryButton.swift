//
//  GhostPrimaryButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.06.2023.
//

import UIKit

final class GhostPrimaryButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .clear }
    override var backgroundDisabledColor: UIColor { .clear }
    override var textColor: UIColor { .foregroundAccent }
    override var textHighlightedColor: UIColor { .foregroundAccentMuted }
    override var textDisabledColor: UIColor { .foregroundAccentMuted }
    override var fontWeight: UIFont.Weight { .medium }
    override var fontSize: CGFloat { 16 }
    override var titleImagePadding: CGFloat { 4 }
    
}
