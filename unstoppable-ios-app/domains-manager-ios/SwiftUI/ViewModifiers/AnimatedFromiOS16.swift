//
//  AnimatedFromiOS16.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import Foundation
import SwiftUI

struct AnimatedFromiOS16: ViewModifier {
    
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .animation(.default, value: UUID())
        } else {
            content
        }
    }
}

extension View {
    func animatedFromiOS16() -> some View {
        self.modifier(AnimatedFromiOS16())
    }
}
