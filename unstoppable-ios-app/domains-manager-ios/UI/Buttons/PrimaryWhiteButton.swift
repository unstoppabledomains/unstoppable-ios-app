//
//  PrimaryWhiteButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.10.2022.
//

import Foundation
import UIKit

final class PrimaryWhiteButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .brandWhite }
    override var backgroundHighlightedColor: UIColor { .brandWhite.withAlphaComponent(0.64) }
    override var backgroundDisabledColor: UIColor { .brandWhite.withAlphaComponent(0.16) }
    override var textColor: UIColor { .brandBlack }
    override var textHighlightedColor: UIColor { .brandBlack }
    override var textDisabledColor: UIColor { .brandBlack }
    override var fontWeight: UIFont.Weight { .medium }
        
}


