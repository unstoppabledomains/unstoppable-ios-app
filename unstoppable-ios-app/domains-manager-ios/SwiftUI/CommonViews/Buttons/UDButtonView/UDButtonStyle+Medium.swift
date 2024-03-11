//
//  UDButtonStyle+Medium.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import SwiftUI

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
