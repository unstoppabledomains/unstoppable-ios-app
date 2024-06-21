//
//  CircularProgressView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import SwiftUI

struct CircularProgressView: View {
    let mode: Mode
    var lineWidth: CGFloat = 10
    @State private var isRotating = false

    var body: some View {
        ZStack {
            // Background for the progress bar
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundStyle(Color.backgroundMuted)
            
            // Foreground or the actual progress bar
            switch mode {
            case .lineProgress(let progress):
                progressCircleView(progress: progress)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: progress)
            case .continuousProgress:
                progressCircleView(progress: 0.3)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isRotating)
                    .onAppear {
                        isRotating = true
                    }
            }
        }
    }
    
    @ViewBuilder
    func progressCircleView(progress: CGFloat) -> some View {
        Circle()
            .trim(from: 0.0, to: min(progress, 1.0))
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .foregroundStyle(Color.foregroundAccent)
    }
    
    enum Mode {
        case lineProgress(CGFloat)
        case continuousProgress
    }
}


#Preview {
    VStack(spacing: 40) {
        CircularProgressView(mode: .lineProgress(0.3))
            .squareFrame(100)
        CircularProgressView(mode: .continuousProgress)
            .squareFrame(100)
    }
}
