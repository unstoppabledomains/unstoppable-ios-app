//
//  InfiniteRotationModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.02.2024.
//

import SwiftUI

struct InfiniteRotationModifier: ViewModifier {
    
    let duration: Double
    let angle: Double
    @State private var isRotating = 0.0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isRotating))
            .onAppear {
                withAnimation(.linear(duration: duration)
                    .repeatForever(autoreverses: false)) {
                        isRotating = angle
                    }
            }
    }
}

extension View {
    func infiniteRotation(duration: Double,
                          angle: Double) -> some View {
        modifier(InfiniteRotationModifier(duration: duration, angle: angle))
    }
}
