//
//  HexagonShape.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 22.08.2023.
//

import SwiftUI

struct HexagonShape: Shape {
    enum Rotation {
        case vertical
        case horizontal
    }
    
    let rotation: Rotation
    var offset: CGPoint = .zero
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            var width: CGFloat = min(rect.size.width, rect.size.height)
            let height = width
            let yOffset: CGFloat = offset.y
            let xScale: CGFloat = 1
            let xOffset = (width * (1.0 - xScale)) / 2.0 + offset.x
            width *= xScale
            
            let segments: [HexagonParameters.Segment]
            switch rotation {
            case .horizontal:
                segments = HexagonParameters.horizontalSegments
            case .vertical:
                segments = HexagonParameters.verticalSegments
            }
            
            let lastSegment = segments.last!
            path.move(
                to: CGPoint(
                    x: width * lastSegment.curve.x + xOffset,
                    y: height * (lastSegment.curve.y + HexagonParameters.adjustment) + yOffset
                )
            )
            
            
            segments.forEach { segment in
                path.addLine(
                    to: CGPoint(
                        x: width * segment.line.x + xOffset,
                        y: height * segment.line.y + yOffset
                    )
                )
                
                
                path.addQuadCurve(
                    to: CGPoint(
                        x: width * segment.curve.x + xOffset,
                        y: height * segment.curve.y + yOffset
                    ),
                    control: CGPoint(
                        x: width * segment.control.x + xOffset,
                        y: height * segment.control.y + yOffset
                    )
                )
            }
        }
    }
    
    struct HexagonParameters {
        
        struct Segment {
            let line: CGPoint
            let curve: CGPoint
            let control: CGPoint
        }
        
        static let adjustment: CGFloat = 0.0
        
        static let horizontalSegments = [
            Segment(
                line:    CGPoint(x: 0.30, y: 0.05),
                curve:   CGPoint(x: 0.20, y: 0.10),
                control: CGPoint(x: 0.25, y: 0.05)
            ),
            Segment(
                line:    CGPoint(x: 0.05, y: 0.40),
                curve:   CGPoint(x: 0.05, y: 0.60),
                control: CGPoint(x: 0.00, y: 0.50)
            ),
            Segment(
                line:    CGPoint(x: 0.20, y: 0.9),
                curve:   CGPoint(x: 0.30, y: 0.95),
                control: CGPoint(x: 0.25, y: 0.95)
            ),
            Segment(
                line:    CGPoint(x: 0.70, y: 0.95),
                curve:   CGPoint(x: 0.80, y: 0.9),
                control: CGPoint(x: 0.75, y: 0.95)
            ),
            Segment(
                line:    CGPoint(x: 0.95, y: 0.60),
                curve:   CGPoint(x: 0.95, y: 0.40),
                control: CGPoint(x: 1.00, y: 0.50)
            ),
            Segment(
                line:    CGPoint(x: 0.80, y: 0.10),
                curve:   CGPoint(x: 0.70, y: 0.05),
                control: CGPoint(x: 0.75, y: 0.05)
            )
        ]
        
        static let verticalSegments = [
            Segment(
                line:    CGPoint(x: 0.60, y: 0.05),
                curve:   CGPoint(x: 0.40, y: 0.05),
                control: CGPoint(x: 0.50, y: 0.00)
            ),
            Segment(
                line:    CGPoint(x: 0.05, y: 0.20 + adjustment),
                curve:   CGPoint(x: 0.00, y: 0.30 + adjustment),
                control: CGPoint(x: 0.00, y: 0.25 + adjustment)
            ),
            Segment(
                line:    CGPoint(x: 0.00, y: 0.70 - adjustment),
                curve:   CGPoint(x: 0.05, y: 0.80 - adjustment),
                control: CGPoint(x: 0.00, y: 0.75 - adjustment)
            ),
            Segment(
                line:    CGPoint(x: 0.40, y: 0.95),
                curve:   CGPoint(x: 0.60, y: 0.95),
                control: CGPoint(x: 0.50, y: 1.00)
            ),
            Segment(
                line:    CGPoint(x: 0.95, y: 0.80 - adjustment),
                curve:   CGPoint(x: 1.00, y: 0.70 - adjustment),
                control: CGPoint(x: 1.00, y: 0.75 - adjustment)
            ),
            Segment(
                line:    CGPoint(x: 1.00, y: 0.30 + adjustment),
                curve:   CGPoint(x: 0.95, y: 0.20 + adjustment),
                control: CGPoint(x: 1.00, y: 0.25 + adjustment)
            )
        ]
    }
    
}
