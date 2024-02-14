//
//  Line.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 22.08.2023.
//

import SwiftUI

struct Line: Shape {
    
    var direction: Direction = .horizontal
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        switch direction {
        case .horizontal:
            path.addLine(to: CGPoint(x: rect.width, y: 0))
        case .vertical:
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        }
        return path
    }
    
    enum Direction {
        case horizontal, vertical
    }
    
}
