//
//  ConfirmSendTokenReviewInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2024.
//

import SwiftUI

struct ConfirmSendTokenReviewInfoView: View {
    
    private let lineWidth: CGFloat = 1
    private let sectionHeight: CGFloat = 48
    private let numberOfSections = 5

    var body: some View {
        ZStack {
            curveLine()
        }
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenReviewInfoView {
    @ViewBuilder
    func curveLine() -> some View {
        ConnectCurve(radius: 24,
                     lineWidth: lineWidth,
                     sectionHeight: sectionHeight,
                     numberOfSections: numberOfSections)
        .stroke(lineWidth: lineWidth)
        .foregroundStyle(Color.white.opacity(0.08))
        .shadow(color: Color.foregroundOnEmphasis2,
                radius: 0, x: 0, y: -1)
        .frame(height: CGFloat(numberOfSections) * sectionHeight)
    }
    
}

// MARK: - Private methods
private extension ConfirmSendTokenReviewInfoView {
    struct ConnectCurve: Shape {
        let radius: CGFloat
        let lineWidth: CGFloat
        let padding: CGFloat = 16
        let sectionHeight: CGFloat
        let numberOfSections: Int
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            for section in 0..<numberOfSections {
                let sectionRect = getRectForSection(section, in: rect)
                if section % 2 == 0 {
                    addCurveFromTopRightToBottomLeft(in: &path,
                                                     rect: sectionRect)
                } else {
                    addCurveFromTopLeftToBottomRight(in: &path,
                                                     rect: sectionRect)
                }
            }
            
            return path
        }
        
        func getRectForSection(_ section: Int,
                               in rect: CGRect) -> CGRect {
            var rect = rect
            rect.size.height = sectionHeight
            rect.origin.y = CGFloat(section) * sectionHeight
            return rect
        }
        
        func addCurveFromTopLeftToBottomRight(in path: inout Path,
                                              rect: CGRect) {
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
                                              rect: CGRect) {
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
            
            let minX = rect.minX + lineWidth + padding
            path.addArc(tangent1End: CGPoint(x: minX,
                                             y: rect.midY),
                        tangent2End: CGPoint(x: minX,
                                             y: rect.maxY),
                        radius: radius,
                        transform: .identity)
        }
        
    }
}

#Preview {
    ConfirmSendTokenReviewInfoView()
}
