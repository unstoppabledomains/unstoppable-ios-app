//
//  LineView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct LineView: View {
    
    var direction: Line.Direction = .horizontal
    var size: CGFloat = 1
    var dashed: Bool = false
    
    var body: some View {
        Line(direction: direction)
            .stroke(style: StrokeStyle(lineWidth: size,
                                       dash: dashed ? [5] : []))
            .modifier(LineFrameForDirectionModifier(direction: direction, size: size))
    }
}

// MARK: - Private methods
private extension LineView {
    struct LineFrameForDirectionModifier: ViewModifier {
        
        let direction: Line.Direction
        let size: CGFloat
        
        func body(content: Content) -> some View {
            switch direction {
            case .horizontal:
                content.frame(height: size)
            case .vertical:
                content.frame(width: size)
            }
        }
        
    }
}

#Preview {
    LineView()
}
