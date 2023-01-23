//
//  ApplePayButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.05.2022.
//

import UIKit

final class ApplePayButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .backgroundEmphasis }
    override var backgroundHighlightedColor: UIColor { .backgroundEmphasis.withAlphaComponent(0.54) }
    override var backgroundDisabledColor: UIColor { .backgroundEmphasis.withAlphaComponent(0.16) }
    
    override var textColor: UIColor { .systemBackground }
    override var textHighlightedColor: UIColor { .systemBackground }
    override var textDisabledColor: UIColor { .systemBackground.withAlphaComponent(0.56) }
    override var fontWeight: UIFont.Weight { .semibold }
    
    override var titleImagePadding: CGFloat { 4 }

    override func setTitle(_ title: String?, image: UIImage?, for state: UIControl.State = .normal) {
        super.setTitle(title, image: .appleIcon, for: state)
    }
    
}

