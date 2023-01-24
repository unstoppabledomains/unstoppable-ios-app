//
//  RaisedTertiaryButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.09.2022.
//

import Foundation
import UIKit

class RaisedTertiaryButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .backgroundMuted2 }
    override var backgroundHighlightedColor: UIColor { .backgroundMuted }
    override var backgroundDisabledColor: UIColor { .backgroundSubtle }
    override var textColor: UIColor { .foregroundDefault }
    override var textHighlightedColor: UIColor { .foregroundDefault }
    override var textDisabledColor: UIColor { .foregroundOnEmphasisOpacity }
    override var fontWeight: UIFont.Weight { .medium }
        
}



