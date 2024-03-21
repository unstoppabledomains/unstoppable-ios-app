//
//  ConfirmSendTokenSenderReceiverConnectView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2024.
//

import SwiftUI

struct ConfirmSendTokenSenderReceiverConnectView: View {
    private let radius: CGFloat = 24
    private let lineWidth: CGFloat = 1
    
    var body: some View {
        ZStack {
            curveLine()
            connectSign()
        }
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenSenderReceiverConnectView {
    @ViewBuilder
    func curveLine() -> some View {
        ConnectCurve(radius: 24,
                     lineWidth: lineWidth)
        .stroke(lineWidth: lineWidth)
        .foregroundStyle(Color.white.opacity(0.08))
        .shadow(color: Color.foregroundOnEmphasis2,
                radius: 0, x: 0, y: -1)
        .frame(height: 48)
    }
    
    @ViewBuilder
    func connectSign() -> some View {
        Image.chevronDoubleDown
            .resizable()
            .squareFrame(24)
            .foregroundStyle(Color.foregroundDefault)
            .padding(4)
            .background(Color.backgroundDefault)
            .shadow(color: Color.backgroundDefault, radius: 0, x: 0, y: 0)
            .clipShape(Circle())
            .overlay(
                ZStack {
                    Circle()
                        .stroke(Color.backgroundDefault, lineWidth: 4)
                    Circle()
                        .stroke(Color.borderDefault, lineWidth: 1)
                }
            )
           
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenSenderReceiverConnectView {
    struct ConnectCurve: Shape {
        let radius: CGFloat
        let lineWidth: CGFloat
        let padding: CGFloat = 16
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let startPoint = CGPoint(x: rect.minX + padding,
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
            return path
        }
    }
    
}

#Preview {
    ConfirmSendTokenSenderReceiverConnectView()
}
