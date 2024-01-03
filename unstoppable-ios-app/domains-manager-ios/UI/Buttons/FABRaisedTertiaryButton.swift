//
//  FABRaisedTertiaryButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2023.
//

import UIKit

final class FABRaisedTertiaryButton: FABButton {
    
    override var backgroundIdleColor: UIColor { .backgroundMuted2 }
    override var backgroundHighlightedColor: UIColor { .backgroundMuted2 }
    override var backgroundDisabledColor: UIColor { .backgroundSubtle }
    override var textColor: UIColor { .foregroundDefault }
    override var textHighlightedColor: UIColor { .foregroundDefault }
    override var textDisabledColor: UIColor { .foregroundMuted }
    override var fabBorderColor: UIColor? { .clear }
    
    
    override func setTitle(_ title: String?, image: UIImage?, for state: UIControl.State = .normal) {
        super.setTitle(title, image: image, for: state)
        
        configuration = .plain()
    }
}
