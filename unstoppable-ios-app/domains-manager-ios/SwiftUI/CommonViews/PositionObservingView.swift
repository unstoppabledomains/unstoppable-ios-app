//
//  PositionObservingView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import SwiftUI

struct PositionObservingView<Content: View>: View {
    var coordinateSpace: CoordinateSpace
    @Binding var position: CGPoint
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .background(GeometryReader { geometry in
                Color.clear.preference(key: PreferenceKey.self,
                                       value: geometry.frame(in: coordinateSpace).origin)
            })
            .onPreferenceChange(PreferenceKey.self) { position in
                self.position = position ?? .zero
            }
    }
}

private extension PositionObservingView {
    struct PreferenceKey: SwiftUI.PreferenceKey {
        static var defaultValue: CGPoint? { nil }
        
        static func reduce(value: inout Value, nextValue: () -> Value) {
            if let nextValue = nextValue() {
                value = nextValue
            }
        }
    }
}
