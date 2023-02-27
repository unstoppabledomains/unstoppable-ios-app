//
//  UIButtonWithExtendedTappableArea.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.02.2023.
//

import UIKit

final class UIButtonWithExtendedTappableArea: UIButton {
    
    var extendedTappableSize: CGSize = CGSize(width: 20,
                                              height: 20)
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds
            .insetBy(dx: -extendedTappableSize.width,
                     dy: -extendedTappableSize.height)
            .contains(point)
    }
    
}
