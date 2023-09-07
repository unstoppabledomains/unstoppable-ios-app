//
//  UBTSearchingView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 09.08.2023.
//

import SwiftUI

struct UBTSearchingView: View {
    
    let profilesFound: Int
    let state: UBTControllerState
    @State private var animate = false
    private let size: CGFloat = 160
    private let sizeStep: CGFloat = 130
    
    private var opacity: CGFloat { animate ? 1 : 0.4 }
    
    var body: some View {
        GeometryReader { geom in
            let largestCircleSize = size + (sizeStep * 7)
            VStack {
                VStack {
                    if case .notReady = state {
                        /// Nothing to show
                    } else {
                        VStack(spacing: 24) {
                            currentIcon()
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                                .opacity(0.48)
                                .rotationEffect(animate ? .degrees(15) : .degrees(60))
                            VStack(spacing: isUnAuthorized ? 24 : 16) {
                                currentTitle()
                                    .foregroundColor(.white)
                                    .font(.currentFont(size: 32, weight: .bold))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.center)
                                if isUnAuthorized {
                                    openSettingsButton()
                                } else {
                                    currentSubtitle()
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .foregroundColor(.white)
                                        .opacity(0.56)
                                        .multilineTextAlignment(.center)
                                        .font(.currentFont(size: 16, weight: .regular))
                                        .padding(EdgeInsets(top: 0, leading: 16,
                                                            bottom: 0, trailing: 16))
                                }
                            }
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
    var isUnAuthorized: Bool {
        if case .unauthorized = state {
            return true
        }
        return false
    }
    
    func currentIcon() -> Image {
        switch state {
        case .notReady, .ready:
            return Image.searchIcon
        case .setupFailed, .unauthorized:
            return Image.grimaseIcon
        }
    }
    
    func currentTitle() -> Text {
        switch state {
        case .notReady, .ready:
            if profilesFound > 0 {
                return Text(String.Constants.pluralNProfilesFound.localized(profilesFound, profilesFound))
            } else {
                return Text(String.Constants.shakeToFindSearchTitle.localized())
            }
        case .setupFailed:
            return Text(String.Constants.shakeToFindFailedTitle.localized())
        case .unauthorized:
            return Text(String.Constants.shakeToFindPermissionsTitle.localized())
        }
    }
    
    func currentSubtitle() -> Text {
        switch state {
        case .notReady, .ready, .unauthorized:
            return Text(String.Constants.shakeToFindSearchSubtitle.localized())
        case .setupFailed:
            return Text(String.Constants.shakeToFindFailedSubtitle.localized())
        }
    }
    
    @ViewBuilder
    func openSettingsButton() -> some View {
        Button {
            openAppSettings()
        } label: {
            Text(String.Constants.openSettings.localized())
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(height: 40, alignment: .center)
                .background(.white.opacity(0.16))
                .cornerRadius(100)
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
        UBTSearchingView(profilesFound: 0, state: .notReady)
    }
}
