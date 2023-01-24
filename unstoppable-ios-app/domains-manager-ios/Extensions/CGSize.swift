//
//  CGSize.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.01.2023.
//

import CoreGraphics

extension CGSize {
    
    static func square(size: CGFloat) -> CGSize {
        CGSize(width: size, height: size)
    }
    
}
