//
//  SquareFrame.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.09.2023.
//

import SwiftUI

struct SquareFrame: ViewModifier {
    
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(width: size,
                   height: size)
    }
}

extension View {
    func squareFrame(_ size: CGFloat) -> some View {
        self.modifier(SquareFrame(size: size))
    }
}
