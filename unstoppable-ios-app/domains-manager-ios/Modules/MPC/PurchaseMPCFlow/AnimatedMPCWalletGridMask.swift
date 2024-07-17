//
//  AnimatedMPCWalletGridMask.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.07.2024.
//

import SwiftUI

struct AnimatedMPCWalletGridMask: View {
    let numShapes: Int = 12  // Number of random shapes
    let animationDuration: Double = 3.0  // Duration for fade in/out animation
    
    @State private var positions: [CGPoint] = []
    @State private var opacities: [Double] = []
    
    init() {
        // Initialize with random positions and opacities
        var points: [CGPoint] = []
        var alphas: [Double] = []
        for _ in 0..<numShapes {
            let x = CGFloat.random(in: 0...1)
            let y = CGFloat.random(in: 0...1)
            points.append(CGPoint(x: x, y: y))
            alphas.append(Double.random(in: 0.7...1))
        }
        self._positions = State(initialValue: points)
        self._opacities = State(initialValue: alphas)
    }
    
    var body: some View {
        ZStack {
            Image.mpcWalletGridAccent
                .resizable()
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<self.numShapes, id: \.self) { index in
                        Circle()
                            .fill(Color.green)
                            .opacity(self.opacities[index])
                            .frame(width: 50, height: 50)
                            .position(x: self.positions[index].x * geometry.size.width,
                                      y: self.positions[index].y * geometry.size.height)
                            .onAppear {
                                Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: true) { _ in
                                    self.updatePositionsAndOpacities()
                                }
                                self.updatePositionsAndOpacities()
                            }
                    }
                }
            }
        }
    }
    
    private func updatePositionsAndOpacities() {
        var points: [CGPoint] = []
        var alphas: [Double] = []
        for _ in 0..<numShapes {
            let x = CGFloat.random(in: 0...1)
            let y = CGFloat.random(in: 0...1)
            points.append(CGPoint(x: x, y: y))
            alphas.append(Double.random(in: 0.4...1))
        }
        withAnimation(Animation.linear(duration: self.animationDuration)) {
            self.positions = points
            self.opacities = alphas
        }
    }
}

