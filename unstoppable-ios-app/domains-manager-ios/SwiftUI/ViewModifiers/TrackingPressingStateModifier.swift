//
//  TrackingPressingStateModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.01.2024.
//

import SwiftUI

struct TrackingPressingStateModifier: ViewModifier {
    enum DragState {
        case empty
    }
    
    @GestureState private var dragState = DragState.empty
    
    let pressedCallback: (Bool)->()
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(LongPressGesture(minimumDuration: 10)
                .updating($dragState) { value, state, transaction in
                    pressedCallback(true)
                })
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onEnded { value in
                    pressedCallback(false)
                })
    }
}

extension View {
    func trackingPressingState(_ pressedCallback: @escaping (Bool)->()) -> some View {
        modifier(TrackingPressingStateModifier(pressedCallback: pressedCallback))
    }
}


