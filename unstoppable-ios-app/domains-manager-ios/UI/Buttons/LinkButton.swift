//
//  LinkButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.04.2022.
//

import UIKit

final class LinkButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .clear }
    override var backgroundDisabledColor: UIColor { .clear }
    override var textColor: UIColor { .foregroundAccent }
    override var textHighlightedColor: UIColor { .foregroundAccentMuted }
    override var textDisabledColor: UIColor { .foregroundAccentSubtle }
    override var fontWeight: UIFont.Weight { .medium }
    
}
