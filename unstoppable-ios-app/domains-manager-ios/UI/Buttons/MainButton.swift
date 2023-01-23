//
//  Buttons.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 30.03.2022.
//

import Foundation
import UIKit

final class MainButton: BaseButton {
    
    var isSuccess: Bool = false {
        didSet {
            self.tintColor = self.textColor
            self.backgroundColor = self.backgroundIdleColor
        }
    }
    
    override var backgroundIdleColor: UIColor {  isSuccess ? .backgroundSuccessEmphasis : .backgroundAccentEmphasis }
    override var backgroundHighlightedColor: UIColor { isSuccess ? .backgroundSuccessEmphasis : .backgroundAccentEmphasis2 }
    override var backgroundDisabledColor: UIColor { isSuccess ? .backgroundSuccessEmphasis : .backgroundAccent }
    
    override var textDisabledColor: UIColor { .foregroundOnEmphasisOpacity }
    override var fontWeight: UIFont.Weight { .semibold }
    
    static let height: CGFloat = 48

}
