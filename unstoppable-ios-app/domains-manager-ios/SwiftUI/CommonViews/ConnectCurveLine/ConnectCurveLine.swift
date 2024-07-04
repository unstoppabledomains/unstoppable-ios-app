//
//  ConnectCurveLine.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.07.2024.
//

import SwiftUI

struct ConnectCurveLine: Shape {
    
    @MainActor
    static var sectionHeight: CGFloat { deviceSize == .i4_7Inch ? 40 : 48 }
    
    var lineWidth: CGFloat = 1
    let padding: CGFloat = 16
    let sectionHeight: CGFloat
    let numberOfSections: Int
    private var radius: CGFloat { sectionHeight / 2 }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for section in 0..<numberOfSections {
            let sectionRect = getRectForSection(section, in: rect)
            if section % 2 == 0 {
                let padding = section == 0 ? self.padding : 0.0
                addCurveFromTopRightToBottomLeft(in: &path,
                                                 rect: sectionRect,
                                                 padding: padding)
            } else {
                addCurveFromTopLeftToBottomRight(in: &path,
                                                 rect: sectionRect,
                                                 padding: 0)
            }
        }
        
        addFinalDot(in: &path, rect: rect)
        
        return path
    }
    
    func addFinalDot(in path: inout Path,
                     rect: CGRect) {
        let rect = getRectForSection(numberOfSections - 1, in: rect)
        let minX = rect.minX + lineWidth
        
        let center = CGPoint(x: minX,
                             y: rect.maxY)
        
        var circlePath = Path()
        circlePath.move(to: center)
        
        for i in 1...2 {
            circlePath.addArc(center: center,
                              radius: CGFloat(i),
                              startAngle: .degrees(0),
                              endAngle: .degrees(360),
                              clockwise: true)
        }
        
        path.addPath(circlePath)
    }
    
    func getRectForSection(_ section: Int,
                           in rect: CGRect) -> CGRect {
        var rect = rect
        rect.size.height = sectionHeight
        rect.origin.y = CGFloat(section) * sectionHeight
        return rect
    }
    
    func addCurveFromTopLeftToBottomRight(in path: inout Path,
                                          rect: CGRect,
                                          padding: CGFloat) {
        let startPoint = CGPoint(x: rect.minX + padding + lineWidth,
                                 y: rect.minY)
        path.move(to: startPoint)
        
        path.addArc(tangent1End: CGPoint(x: startPoint.x,
                                         y: rect.midY),
                    tangent2End: CGPoint(x: rect.minX + radius + padding,
                                         y: rect.midY),
                    radius: radius,
                    transform: .identity)
        
        path.addLine(to: CGPoint(x: rect.maxX - radius - padding,
                                 y: rect.midY))
        
        let maxX = rect.maxX - lineWidth - padding
        path.addArc(tangent1End: CGPoint(x: maxX,
                                         y: rect.midY),
                    tangent2End: CGPoint(x: maxX,
                                         y: rect.maxY),
                    radius: radius,
                    transform: .identity)
    }
    
    func addCurveFromTopRightToBottomLeft(in path: inout Path,
                                          rect: CGRect,
                                          padding: CGFloat) {
        let startPoint = CGPoint(x: rect.maxX - padding - lineWidth,
                                 y: rect.minY)
        path.move(to: startPoint)
        
        path.addArc(tangent1End: CGPoint(x: startPoint.x,
                                         y: rect.midY),
                    tangent2End: CGPoint(x: rect.maxX - radius - padding,
                                         y: rect.midY),
                    radius: radius,
                    transform: .identity)
        
        path.addLine(to: CGPoint(x: rect.minX + radius + padding,
                                 y: rect.midY))
        
        let minX = rect.minX + lineWidth
        path.addArc(tangent1End: CGPoint(x: minX,
                                         y: rect.midY),
                    tangent2End: CGPoint(x: minX,
                                         y: rect.maxY),
                    radius: radius,
                    transform: .identity)
    }
    
}

#Preview {
    ConnectCurveLine(sectionHeight: 48,
                     numberOfSections: 3)
}
