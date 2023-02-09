//
//  SmallRaisedTertiaryButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.12.2022.
//

import UIKit

final class SmallRaisedTertiaryButton: RaisedTertiaryButton {
    
    override var textDisabledColor: UIColor { .foregroundDefault }
    override var fontWeight: UIFont.Weight { .medium }
    override var fontSize: CGFloat { 14 }
    
}
