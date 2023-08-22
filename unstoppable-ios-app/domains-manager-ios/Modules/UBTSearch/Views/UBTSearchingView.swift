//
//  UBTSearchingView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 09.08.2023.
//

import SwiftUI

struct UBTSearchingView: View {
    
    let profilesFound: Int
    @State private var animate = false
    private let size: CGFloat = 160
    private let sizeStep: CGFloat = 130

    private var opacity: CGFloat { animate ? 1 : 0.4 }
    
    var body: some View {
        GeometryReader { geom in
            let largestCircleSize = size + (sizeStep * 7)
            VStack {
                VStack {
                    VStack(spacing: 24) {
                        Image.searchIcon
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .opacity(0.48)
                            .rotationEffect(animate ? .degrees(15) : .degrees(60))
                        VStack(spacing: 16) {
                            currentTitle()
                                .foregroundColor(.white)
                                .font(.currentFont(size: 32, weight: .bold))
                            Text(String.Constants.shakeToFindSearchSubtitle.localized())
                                .lineLimit(2)
                                .foregroundColor(.white)
                                .opacity(0.56)
                                .multilineTextAlignment(.center)
                                .font(.currentFont(size: 16, weight: .regular))
                        }
                    }
                }
                .offset(y: (geom.size.height / 2) - 222)
                
                VStack {
                    circlesView()
                        .rotation3DEffect(.degrees(50), axis: (1, 0, 0), anchor: .bottom,  perspective: 0)
                        .animation(animate ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: animate)
                }
                .offset(y: (geom.size.height - 230) - (largestCircleSize / 2))
            }
            .offset(x: (geom.size.width - largestCircleSize) / 2)
        }
        .onAppear { self.animate = true }
    }
    
}

// MARK: - Private methods
private extension UBTSearchingView {
    func currentTitle() -> Text {
        if profilesFound > 0 {
            return Text(String.Constants.pluralNProfilesFound.localized(profilesFound, profilesFound))
        } else {
            return Text(String.Constants.shakeToFindSearchTitle.localized())
        }
    }
    
    func backgroundCircleWith(opacity: CGFloat, size: CGFloat) -> some View {
        Circle()
            .stroke(.white, lineWidth: 1)
            .frame(width: size, height: size)
            .opacity(opacity)
    }
    
    @ViewBuilder
    func circlesView() -> some View {
        ZStack {
            backgroundCircleWith(opacity: opacity, size: size + (sizeStep * 7))
            backgroundCircleWith(opacity: opacity, size: size + (sizeStep * 6))
            backgroundCircleWith(opacity: opacity, size: size + (sizeStep * 5))
            backgroundCircleWith(opacity: opacity, size: size + (sizeStep * 4))
            backgroundCircleWith(opacity: opacity, size: size + (sizeStep * 3))
            backgroundCircleWith(opacity: opacity, size: size + (sizeStep * 2))
            backgroundCircleWith(opacity: opacity, size: size + (sizeStep * 1))
            backgroundCircleWith(opacity: opacity, size: size)
        }
    }
    
    struct AnimatableCircle: View {
        let size: CGFloat
        @State private var animate = false
        private var opacity: CGFloat { animate ? 1 : 0.4 }
        private var scale: CGFloat { animate ? 1 : 0.9 }

        var body: some View {
            Circle()
                .stroke(.blue, lineWidth: 1)
                .frame(width: size, height: size)
                .opacity(opacity)
                .scaleEffect(scale)
        }
    }
}

struct BTSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        UBTSearchingView(profilesFound: 0)
    }
}
