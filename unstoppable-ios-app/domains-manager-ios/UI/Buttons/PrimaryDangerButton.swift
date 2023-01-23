//
//  PrimaryDangerButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.05.2022.
//

import Foundation
import UIKit

final class PrimaryDangerButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .backgroundDangerEmphasis }
    override var backgroundHighlightedColor: UIColor { .backgroundDangerEmphasis2 }
    override var backgroundDisabledColor: UIColor { .backgroundDanger }
    override var textDisabledColor: UIColor { .foregroundOnEmphasisOpacity } 
    override var fontWeight: UIFont.Weight { .semibold }
    
    static let height: CGFloat = 48
    
}


