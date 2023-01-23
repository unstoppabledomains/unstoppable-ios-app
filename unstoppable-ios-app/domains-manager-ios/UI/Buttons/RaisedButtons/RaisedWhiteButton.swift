//
//  RaisedWhiteButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.10.2022.
//

import Foundation
import UIKit

final class RaisedWhiteButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .white }
    override var backgroundHighlightedColor: UIColor { .white.withAlphaComponent(0.64) }
    override var backgroundDisabledColor: UIColor { .white.withAlphaComponent(0.16) }
    override var textColor: UIColor { .black }
    override var textHighlightedColor: UIColor { .black }
    override var textDisabledColor: UIColor { .black }
    override var fontWeight: UIFont.Weight { .medium }

}
