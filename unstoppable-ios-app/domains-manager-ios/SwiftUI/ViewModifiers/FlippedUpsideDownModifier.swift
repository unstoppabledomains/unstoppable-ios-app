//
//  FlippedUpsideDownModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

struct FlippedUpsideDown: ViewModifier {
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(180))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}
extension View{
    func flippedUpsideDown() -> some View{
        self.modifier(FlippedUpsideDown())
    }
}
