//
//  ResendCodeButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import UIKit

final class ResendCodeButton: BaseButton {

    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .clear }
    override var backgroundDisabledColor: UIColor { .clear }
    override var textColor: UIColor { .foregroundAccent }
    override var textHighlightedColor: UIColor { .foregroundAccentMuted }
    override var textDisabledColor: UIColor { .foregroundSecondary }
    override var fontWeight: UIFont.Weight { .medium }
    override var fontSize: CGFloat { 12 }
}
