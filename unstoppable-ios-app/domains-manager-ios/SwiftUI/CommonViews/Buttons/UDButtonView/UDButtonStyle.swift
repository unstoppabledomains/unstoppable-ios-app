//
//  UDButtonStyle.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 20.11.2023.
//

import SwiftUI

enum UDButtonStyle {
    case verySmall(VerySmallStyle), small(SmallStyle), medium(MediumStyle), large(LargeStyle)
    
    var name: String {
        switch self {
        case .verySmall(let verySmallStyle):
            return verySmallStyle.rawValue
        case .small(let smallStyle):
            return smallStyle.rawValue
        case .medium(let mediumStyle):
            return mediumStyle.rawValue
        case .large(let largeStyle):
            return largeStyle.rawValue
        }
    }
    
    @ViewBuilder
    var backgroundIdleColor: some View {
        switch self {
        case .verySmall(let verySmallStyle):
            verySmallStyle.backgroundIdleColor
        case .small(let smallStyle):
            smallStyle.backgroundIdleColor
        case .medium(let mediumStyle):
            mediumStyle.backgroundIdleColor
        case .large(let largeStyle):
            largeStyle.backgroundIdleColor
        }
    }
    
    @ViewBuilder
    var backgroundIdleGradient: some View {
        switch self {
        case .verySmall:
            EmptyView()
        case .small(let smallStyle):
            smallStyle.backgroundIdleGradient
        case .medium(let mediumStyle):
            mediumStyle.backgroundIdleGradient
        case .large(let largeStyle):
            largeStyle.backgroundIdleGradient
        }
    }
    
    @ViewBuilder
    var backgroundHighlightedGradient: some View {
        switch self {
        case .verySmall:
            EmptyView()
        case .small(let smallStyle):
            smallStyle.backgroundHighlightedGradient
        case .medium(let mediumStyle):
            mediumStyle.backgroundHighlightedGradient
        case .large(let largeStyle):
            largeStyle.backgroundHighlightedGradient
        }
    }
    
    var backgroundHighlightedColor: Color {
        switch self {
        case .verySmall(let verySmallStyle):
            return verySmallStyle.backgroundHighlightedColor
        case .small(let smallStyle):
            return smallStyle.backgroundHighlightedColor
        case .medium(let mediumStyle):
            return mediumStyle.backgroundHighlightedColor
        case .large(let largeStyle):
            return largeStyle.backgroundHighlightedColor
        }
    }
    var backgroundDisabledColor: Color {
        switch self {
        case .verySmall(let verySmallStyle):
            return verySmallStyle.backgroundDisabledColor
        case .small(let smallStyle):
            return smallStyle.backgroundDisabledColor
        case .medium(let mediumStyle):
            return mediumStyle.backgroundDisabledColor
        case .large(let largeStyle):
            return largeStyle.backgroundDisabledColor
        }
    }
    var backgroundSuccessColor: Color {
        switch self {
        case .verySmall(let verySmallStyle):
            return verySmallStyle.backgroundSuccessColor
        case .small(let smallStyle):
            return smallStyle.backgroundSuccessColor
        case .medium(let mediumStyle):
            return mediumStyle.backgroundSuccessColor
        case .large(let largeStyle):
            return largeStyle.backgroundSuccessColor
        }
    }
    var textColor: Color {
        switch self {
        case .verySmall(let verySmallStyle):
            return verySmallStyle.textColor
        case .small(let smallStyle):
            return smallStyle.textColor
        case .medium(let mediumStyle):
            return mediumStyle.textColor
        case .large(let largeStyle):
            return largeStyle.textColor
        }
    }
    var textHighlightedColor: Color {
        switch self {
        case .verySmall(let verySmallStyle):
            return verySmallStyle.textHighlightedColor
        case .small(let smallStyle):
            return smallStyle.textHighlightedColor
        case .medium(let mediumStyle):
            return mediumStyle.textHighlightedColor
        case .large(let largeStyle):
            return largeStyle.textHighlightedColor
        }
    }
    var textDisabledColor: Color {
        switch self {
        case .verySmall(let verySmallStyle):
            return verySmallStyle.textDisabledColor
        case .small(let smallStyle):
            return smallStyle.textDisabledColor
        case .medium(let mediumStyle):
            return mediumStyle.textDisabledColor
        case .large(let largeStyle):
            return largeStyle.textDisabledColor
        }
    }
    var textSuccessColor: Color {
        switch self {
        case .verySmall(let verySmallStyle):
            return verySmallStyle.textSuccessColor
        case .small(let smallStyle):
            return smallStyle.textSuccessColor
        case .medium(let mediumStyle):
            return mediumStyle.textSuccessColor
        case .large(let largeStyle):
            return largeStyle.textSuccessColor
        }
    }
    var font: Font {
        switch self {
        case .large:
            return .currentFont(size: 16, weight: .semibold)
        case .medium:
            return .currentFont(size: 16, weight: .medium)
        case .small:
            return .currentFont(size: 14, weight: .medium)
        case .verySmall:
            return .currentFont(size: 12, weight: .medium)
        }
    }
    var iconSize: CGFloat {
        switch self {
        case .large, .medium:
            return 20
        case .small:
            return 16
        case .verySmall:
            return 12
        }
    }
    var titleImagePadding: CGFloat {
        switch self {
        case .large, .medium, .small:
            return 8
        case .verySmall:
            return 4
        }
    }
    var height: CGFloat {
        switch self {
        case .large:
            return 48
        case .medium:
            return 40
        case .small:
            return 32
        case .verySmall:
            return 16
        }
    }
    var cornerRadius: CGFloat {
        switch self {
        case .large:
            return 12
        case .medium, .small, .verySmall:
            return height / 2
        }
    }
    var isSupportingSubhead: Bool {
        switch self {
        case .large:
            return true
        case .medium, .small, .verySmall:
            return false
        }
    }
}

// MARK: - LargeStyle
extension UDButtonStyle {
    enum LargeStyle: String, CaseIterable, UDButtonViewSubviewsBuilder {
        case raisedPrimary, raisedPrimaryWhite, raisedDanger, raisedTertiary, raisedTertiaryWhite
        case ghostPrimary, ghostDanger
        case applePay
        
        var backgroundIdleColor: some View {
            switch self {
            case .raisedPrimary:
                return Color.backgroundAccentEmphasis
            case .raisedPrimaryWhite:
                return Color.brandWhite
            case .raisedDanger:
                return Color.backgroundDangerEmphasis
            case .raisedTertiary:
                return Color.backgroundOverlay
            case .raisedTertiaryWhite:
                return Color.brandWhite.opacity(0.16)
            case .ghostPrimary, .ghostDanger:
                return Color.clear
            case .applePay:
                return Color.black
            }
        }
        
        @ViewBuilder
        var backgroundIdleGradient: some View {
            switch self {
            case .raisedPrimary, .raisedDanger, .applePay:
                gradientWith(.white.opacity(0.32),
                             .white.opacity(0.0))
            case .raisedTertiary:
                gradientWith(.white.opacity(0.08),
                             .white.opacity(0.0))
            case .raisedPrimaryWhite, .raisedTertiaryWhite, .ghostPrimary, .ghostDanger:
                EmptyView()
            }
        }
        
        @ViewBuilder
        var backgroundHighlightedGradient: some View {
            switch self {
            case .raisedPrimary, .raisedDanger, .applePay:
                gradientWith(.white.opacity(0.44),
                             .white.opacity(0.0))
            case .raisedTertiary, .raisedPrimaryWhite:
                gradientWith(.black.opacity(0.0),
                             .black.opacity(0.04))
            case .raisedTertiaryWhite, .ghostPrimary, .ghostDanger:
                EmptyView()
            }
        }
        
        var backgroundHighlightedColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccentEmphasis2
            case .raisedPrimaryWhite:
                return .brandWhite
            case .raisedDanger:
                return .backgroundDangerEmphasis2
            case .raisedTertiary:
                return .backgroundOverlay
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.24)
            case .ghostPrimary, .ghostDanger:
                return .backgroundMuted
            case .applePay:
                return .black.opacity(0.64)
            }
        }
        
        var backgroundDisabledColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccent
            case .raisedPrimaryWhite:
                return .brandWhite.opacity(0.16)
            case .raisedDanger:
                return .backgroundDanger
            case .raisedTertiary:
                return .backgroundSubtle
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.08)
            case .ghostPrimary, .ghostDanger:
                return .clear
            case .applePay:
                return .black.opacity(0.16)
            }
        }
        
        var backgroundSuccessColor: Color {
            switch self {
            case .raisedPrimary, .raisedPrimaryWhite, .raisedDanger:
                return .backgroundSuccessEmphasis
            case .raisedTertiary, .raisedTertiaryWhite:
                return .backgroundSuccess
            case .ghostPrimary, .ghostDanger, .applePay:
                return .clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .raisedPrimary, .raisedDanger:
                return .foregroundOnEmphasis
            case .raisedPrimaryWhite:
                return .black
            case .raisedTertiary:
                return .foregroundDefault
            case .raisedTertiaryWhite:
                return .brandWhite
            case .ghostPrimary:
                return .foregroundAccent
            case .ghostDanger:
                return .foregroundDanger
            case .applePay:
                return .foregroundOnEmphasis
            }
        }
        
        var textHighlightedColor: Color { textColor }
        
        var textDisabledColor: Color {
            switch self {
            case .raisedPrimary, .raisedDanger, .applePay:
                return .foregroundOnEmphasis.opacity(0.56)
            case .raisedPrimaryWhite:
                return .black
            case .raisedTertiary:
                return .foregroundMuted
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.32)
            case .ghostPrimary:
                return .foregroundAccent.opacity(0.48)
            case .ghostDanger:
                return .foregroundDanger.opacity(0.48)
            }
        }
        
        var textSuccessColor: Color {
            switch self {
            case .raisedPrimary, .raisedPrimaryWhite, .raisedDanger:
                return .foregroundOnEmphasis
            case .raisedTertiary, .raisedTertiaryWhite, .ghostPrimary, .ghostDanger, .applePay:
                return .foregroundSuccess
            }
        }
    }
}

// MARK: - MediumStyle
extension UDButtonStyle {
    enum MediumStyle: String, CaseIterable, UDButtonViewSubviewsBuilder {
        case raisedPrimary, raisedPrimaryWhite, raisedTertiary, raisedTertiaryWhite
        case ghostPrimary, ghostPrimaryWhite, ghostTertiary, ghostTertiaryWhite
        
        var backgroundIdleColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccentEmphasis
            case .raisedPrimaryWhite:
                return .brandWhite
            case .raisedTertiary:
                return .backgroundOverlay
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.24)
            case .ghostPrimary, .ghostPrimaryWhite, .ghostTertiary, .ghostTertiaryWhite:
                return .clear
            }
        }
        
        @ViewBuilder
        var backgroundIdleGradient: some View {
            switch self {
            case .raisedPrimary:
                gradientWith(.white.opacity(0.32),
                             .white.opacity(0.0))
            case .raisedTertiary:
                gradientWith(.white.opacity(0.08),
                             .white.opacity(0.0))
            case .raisedPrimaryWhite, .raisedTertiaryWhite, .ghostPrimary, .ghostPrimaryWhite, .ghostTertiary, .ghostTertiaryWhite:
                EmptyView()
            }
        }
        
        var backgroundHighlightedColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccentEmphasis2
            case .raisedPrimaryWhite:
                return .brandWhite.opacity(0.64)
            case .raisedTertiary:
                return .backgroundOverlay
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.24)
            case .ghostPrimary, .ghostPrimaryWhite, .ghostTertiary, .ghostTertiaryWhite:
                return .clear
            }
        }
        
        @ViewBuilder
        var backgroundHighlightedGradient: some View {
            switch self {
            case .raisedPrimary:
                gradientWith(.white.opacity(0.44),
                             .white.opacity(0.0))
            case .raisedTertiary:
                gradientWith(.black.opacity(0.0),
                             .black.opacity(0.04))
            case .raisedTertiaryWhite, .ghostPrimary, .raisedPrimaryWhite, .ghostPrimaryWhite, .ghostTertiary, .ghostTertiaryWhite:
                EmptyView()
            }
        }
        
        var backgroundDisabledColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccent
            case .raisedPrimaryWhite:
                return .brandWhite.opacity(0.64)
            case .raisedTertiary:
                return .backgroundSubtle
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.08)
            case .ghostPrimary, .ghostPrimaryWhite, .ghostTertiary, .ghostTertiaryWhite:
                return .clear
            }
        }
        
        var backgroundSuccessColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundSuccessEmphasis
            case .raisedPrimaryWhite ,.raisedTertiary, .raisedTertiaryWhite:
                return .backgroundSuccess
            case .ghostPrimary, .ghostPrimaryWhite, .ghostTertiary, .ghostTertiaryWhite:
                return .clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .raisedPrimary:
                return .foregroundOnEmphasis
            case .raisedPrimaryWhite:
                return .black
            case .raisedTertiary:
                return .foregroundDefault
            case .raisedTertiaryWhite:
                return .brandWhite
            case .ghostPrimary:
                return .foregroundAccent
            case .ghostPrimaryWhite:
                return .brandWhite
            case .ghostTertiary:
                return .foregroundSecondary
            case .ghostTertiaryWhite:
                return .brandWhite.opacity(0.56)
            }
        }
        
        var textHighlightedColor: Color {
            switch self {
            case .raisedPrimary, .raisedPrimaryWhite, .raisedTertiary, .raisedTertiaryWhite:
                return textColor
            case .ghostPrimary:
                return .foregroundAccentMuted
            case .ghostPrimaryWhite:
                return .brandWhite.opacity(0.32)
            case .ghostTertiary:
                return .foregroundMuted
            case .ghostTertiaryWhite:
                return .brandWhite.opacity(0.32)
            }
        }
        
        var textDisabledColor: Color {
            switch self {
            case .raisedPrimary:
                return .foregroundOnEmphasisOpacity
            case .raisedPrimaryWhite:
                return .black
            case .raisedTertiary:
                return .foregroundMuted
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.32)
            case .ghostPrimary:
                return .foregroundAccentMuted
            case .ghostPrimaryWhite:
                return .brandWhite.opacity(0.24)
            case .ghostTertiary:
                return .foregroundMuted
            case .ghostTertiaryWhite:
                return .brandWhite.opacity(0.24)
            }
        }
        
        var textSuccessColor: Color {
            switch self {
            case .raisedPrimary:
                return .foregroundOnEmphasis
            case .raisedPrimaryWhite, .raisedTertiary, .raisedTertiaryWhite, .ghostPrimary, .ghostPrimaryWhite, .ghostTertiary, .ghostTertiaryWhite:
                return .foregroundSuccess
            }
        }
    }
}

// MARK: - SmallStyle
extension UDButtonStyle {
    enum SmallStyle: String, CaseIterable, UDButtonViewSubviewsBuilder  {
        case raisedPrimary, raisedPrimaryWhite, raisedTertiaryWhite, raisedTertiary
        case ghostPrimary, ghostPrimaryWhite, ghostPrimaryWhite2
        
        var backgroundIdleColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccentEmphasis
            case .raisedPrimaryWhite:
                return .brandWhite
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.16)
            case .raisedTertiary:
                return .backgroundOverlay
            case .ghostPrimary, .ghostPrimaryWhite, .ghostPrimaryWhite2:
                return .clear
            }
        }
        
        @ViewBuilder
        var backgroundIdleGradient: some View {
            switch self {
            case .raisedPrimary:
                gradientWith(.white.opacity(0.32),
                             .white.opacity(0.0))
            case .raisedTertiary:
                gradientWith(.white.opacity(0.08),
                             .white.opacity(0.0))
            default:
                EmptyView()
            }
        }
        
        var backgroundHighlightedColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccentEmphasis2
            case .raisedPrimaryWhite:
                return .brandWhite.opacity(0.64)
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.24)
            case .raisedTertiary:
                return .backgroundOverlay
            case .ghostPrimary, .ghostPrimaryWhite, .ghostPrimaryWhite2:
                return .clear
            }
        }
        
        @ViewBuilder
        var backgroundHighlightedGradient: some View {
            switch self {
            case .raisedPrimary:
                gradientWith(.white.opacity(0.44),
                             .white.opacity(0.0))
            case .raisedTertiary:
                gradientWith(.black.opacity(0.0),
                             .black.opacity(0.04))
            default:
                EmptyView()
            }
        }
        
        var backgroundDisabledColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccent
            case .raisedPrimaryWhite:
                return .brandWhite.opacity(0.16)
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.08)
            case .raisedTertiary:
                return .backgroundSubtle
            case .ghostPrimary, .ghostPrimaryWhite, .ghostPrimaryWhite2:
                return .clear
            }
        }
        
        var backgroundSuccessColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundSuccessEmphasis
            case .raisedPrimaryWhite, .raisedTertiaryWhite, .raisedTertiary:
                return .backgroundSuccess
            case .ghostPrimary, .ghostPrimaryWhite, .ghostPrimaryWhite2:
                return .clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .raisedPrimary:
                return .foregroundOnEmphasis
            case .raisedPrimaryWhite:
                return .black
            case .raisedTertiaryWhite:
                return .brandWhite
            case .raisedTertiary:
                return .foregroundDefault
            case .ghostPrimary:
                return .foregroundAccent
            case .ghostPrimaryWhite:
                return .brandWhite
            case .ghostPrimaryWhite2:
                return .brandWhite.opacity(0.56)
            }
        }
        
        var textHighlightedColor: Color {
            switch self {
            case .raisedPrimary, .raisedPrimaryWhite, .raisedTertiaryWhite, .raisedTertiary:
                return textColor
            case .ghostPrimary:
                return .foregroundAccentMuted
            case .ghostPrimaryWhite:
                return .brandWhite.opacity(0.32)
            case .ghostPrimaryWhite2:
                return .brandWhite.opacity(0.32)
            }
        }
        
        var textDisabledColor: Color {
            switch self {
            case .raisedPrimary:
                return .foregroundOnEmphasisOpacity
            case .raisedPrimaryWhite:
                return .black
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.32)
            case .raisedTertiary:
                return .foregroundMuted
            case .ghostPrimary:
                return .foregroundAccentMuted
            case .ghostPrimaryWhite:
                return .brandWhite.opacity(0.24)
            case .ghostPrimaryWhite2:
                return .brandWhite.opacity(0.24)
            }
        }
        
        var textSuccessColor: Color {
            switch self {
            case .raisedPrimary:
                return .foregroundOnEmphasis
            case .raisedPrimaryWhite, .raisedTertiaryWhite, .raisedTertiary, .ghostPrimary, .ghostPrimaryWhite, .ghostPrimaryWhite2:
                return .foregroundSuccess
            }
        }
    }
}

// MARK: - VerySmallStyle
extension UDButtonStyle {
    enum VerySmallStyle: String, CaseIterable {
        case ghostTertiary, ghostPrimary
        
        var backgroundIdleColor: Color {
            switch self {
            case .ghostPrimary, .ghostTertiary:
                return .clear
            }
        }
        
        var backgroundHighlightedColor: Color {
            switch self {
            case .ghostPrimary, .ghostTertiary:
                return .clear
            }
        }
        
        var backgroundDisabledColor: Color {
            switch self {
            case .ghostPrimary, .ghostTertiary:
                return .clear
            }
        }
        
        var backgroundSuccessColor: Color {
            switch self {
            case .ghostPrimary, .ghostTertiary:
                return .clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .ghostPrimary:
                return .foregroundAccent
            case .ghostTertiary:
                return .foregroundSecondary
            }
        }
        
        var textHighlightedColor: Color {
            switch self {
            case .ghostPrimary:
                return .foregroundAccentMuted
            case .ghostTertiary:
                return .foregroundMuted
            }
        }
        
        var textDisabledColor: Color {
            switch self {
            case .ghostPrimary:
                return .foregroundAccentMuted
            case .ghostTertiary:
                return .foregroundMuted
            }
        }
        
        var textSuccessColor: Color {
            switch self {
            case .ghostPrimary, .ghostTertiary:
                return .foregroundSuccess
            }
        }
    }
}

protocol UDButtonViewSubviewsBuilder { }

extension UDButtonViewSubviewsBuilder {
    func gradientWith(_ topColor: Color,
                      _ bottomColor: Color) -> LinearGradient {
        LinearGradient(
            stops: [
                Gradient.Stop(color: topColor, location: 0.00),
                Gradient.Stop(color: bottomColor, location: 1.00),
            ],
            startPoint: UnitPoint(x: 0.49, y: 0),
            endPoint: UnitPoint(x: 0.49, y: 1)
        )
    }
}
