//
//  GhostTertiaryButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.12.2022.
//

import UIKit

final class GhostTertiaryButton: BaseButton {
    
    var isSuccess: Bool = false {
        didSet { self.tintColor = self.textColor }
    }
    
    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .clear }
    override var backgroundDisabledColor: UIColor { .clear }
    override var textColor: UIColor { isSuccess ? .foregroundSuccess : .foregroundSecondary }
    override var textHighlightedColor: UIColor { isSuccess ? .foregroundSuccess : .foregroundMuted }
    override var textDisabledColor: UIColor { isSuccess ? .foregroundSuccess : .foregroundMuted }
    override var fontWeight: UIFont.Weight { .medium }
    override var fontSize: CGFloat { 12 }
    override var titleImagePadding: CGFloat { 4 }
    
}
