//
//  UDButtonStyle+Small.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import SwiftUI

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
