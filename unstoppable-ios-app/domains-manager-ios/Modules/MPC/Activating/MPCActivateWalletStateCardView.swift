//
//  MPCActivateWalletStateCardView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import SwiftUI

struct MPCActivateWalletStateCardView: View {
    
    let title: String
    let mode: Mode
    let mpcCreateProgress: Double
    
    var body: some View {
        ZStack {
            Image.mpcWalletGrid
                .resizable()
            Image.mpcWalletGridAccent
                .resizable()
                .foregroundStyle(stateBorderColor())
            HStack(spacing: 100) {
                mpcStateBlurLine()
                mpcStateBlurLine()
            }
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    stateProgressView()
                        .squareFrame(56)
                    Spacer()
                    numberBadgeView()
                }
                Spacer()
                
                mpcStateLabelsView()
            }
            .padding(16)
        }
        .foregroundStyle(Color.foregroundDefault)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(stateBackgroundView())
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.backgroundDefault, lineWidth: 4)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(stateBorderColor(), lineWidth: 1)
            }
        )
        .padding(32)
    }
    
}

// MARK: - Private methods
private extension MPCActivateWalletStateCardView {
    @ViewBuilder
    func mpcStateBlurLine() -> some View {
        Rectangle()
            .foregroundColor(.clear)
            .frame(width: 15)
            .background(Color.foregroundMuted)
            .blur(radius: 32)
            .rotationEffect(.degrees(45))
    }
    
    @ViewBuilder
    func mpcStateLabelsView() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.currentFont(size: 28, weight: .bold))
                    .foregroundStyle(Color.foregroundDefault)
                    .minimumScaleFactor(0.6)
                Text(subtitle)
                    .font(.currentFont(size: 16))
                    .foregroundStyle(Color.foregroundDefault)
            }
            .lineLimit(1)
            Spacer()
        }
    }
    
    var subtitle: String {
        String.Constants.mpcProductName.localized()
    }
    
    @ViewBuilder
    func numberBadgeView() -> some View {
        HStack(alignment: .center, spacing: 4) {
            badgeVerticalDotsView()
            Text("#00001")
                .monospaced()
                .foregroundColor(Color.foregroundDefault)
            badgeVerticalDotsView()
        }
        .padding(4)
        .frame(height: 24, alignment: .center)
        .background(badgeBackgroundColor)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .inset(by: -0.5)
                .stroke(badgeBorderColor, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    var badgeBackgroundColor: some View {
        switch mode {
        case .activation(let activationState):
            switch activationState {
            case .readyToActivate, .activating, .failed:
                Color.backgroundMuted
                    .background(.regularMaterial)
            case .activated:
                Color.white.opacity(0.44)
            }
        }
    }
    
    var badgeBorderColor: Color {
        switch mode {
        case .activation(let activationState):
            switch activationState {
            case .readyToActivate, .activating, .failed:
                    .backgroundDefault
            case .activated:
                    .black.opacity(0.16)
            }
        }
    }
    
    @ViewBuilder
    func badgeDotView() -> some View {
        Circle()
            .squareFrame(2)
            .foregroundStyle(badgeDotBackgroundColor)
            .padding(.vertical, 4)
    }
    
    var badgeDotBackgroundColor: Color {
        switch mode {
        case .activation(let activationState):
            switch activationState {
            case .readyToActivate, .activating, .failed:
                    .foregroundMuted
            case .activated:
                    .white.opacity(0.32)
            }
        }
    }
    
    @ViewBuilder
    func badgeVerticalDotsView() -> some View {
        VStack(alignment: .center) {
            badgeDotView()
            Spacer()
            badgeDotView()
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 4)
        .frame(height: 24, alignment: .center)
    }
    
    @ViewBuilder
    func stateProgressView() -> some View {
        switch mode {
        case .activation(let activationState):
            switch activationState {
            case .readyToActivate, .activating:
                CircularProgressView(progress: mpcCreateProgress)
            case .activated:
                Image.checkCircle
                    .resizable()
                    .foregroundStyle(.white)
            case .failed:
                Image.crossWhite
                    .resizable()
                    .foregroundStyle(stateBorderColor())
            }
        }
    }
    
    @ViewBuilder
    func stateBackgroundView() -> some View {
        switch mode {
        case .activation(let activationState):
            switch activationState {
            case .readyToActivate, .activating, .failed:
                Color.backgroundOverlay
            case .activated:
                Color.backgroundSuccessEmphasis
            }
        }
    }
    
    func stateBorderColor() -> Color {
        switch mode {
        case .activation(let activationState):
            switch activationState {
            case .readyToActivate, .activating:
                    .foregroundAccent
            case .activated:
                    .backgroundSuccessEmphasis
            case .failed:
                    .backgroundDangerEmphasis
            }
        }
    }
}

// MARK: - Open methods
extension MPCActivateWalletStateCardView {
    enum Mode {
        case activation(MPCWalletActivationState)
    }
}

#Preview {
    MPCActivateWalletStateCardView(title: "Activating...",
                                   mode: .activation(.readyToActivate),
                                   mpcCreateProgress: 0.3)
}
