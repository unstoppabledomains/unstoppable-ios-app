//
//  RaisedTertiaryWhiteButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.10.2022.
//

import Foundation
import UIKit

class RaisedTertiaryWhiteButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .white.withAlphaComponent(0.16) }
    override var backgroundHighlightedColor: UIColor { .white.withAlphaComponent(0.24) }
    override var backgroundDisabledColor: UIColor { .white.withAlphaComponent(0.08) }
    override var textColor: UIColor { .white }
    override var textHighlightedColor: UIColor { .white }
    override var textDisabledColor: UIColor { .white.withAlphaComponent(0.32) }
    override var fontWeight: UIFont.Weight { .medium }
        
}

final class SmallRaisedTertiaryWhiteButton: RaisedTertiaryWhiteButton {
    
    override var fontSize: CGFloat { 14 }
    
}
