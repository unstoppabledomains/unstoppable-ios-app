//
//  UDButtonStyle+Large.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import SwiftUI

// MARK: - LargeStyle
extension UDButtonStyle {
    enum LargeStyle: String, CaseIterable, UDButtonViewSubviewsBuilder {
        case raisedPrimary, raisedPrimaryWhite, raisedDanger, raisedTertiary, raisedTertiaryWhite
        case ghostPrimary, ghostDanger
        case applePay, applePayWhite
        
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
            case .applePayWhite:
                return Color.white
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
            case .raisedPrimaryWhite, .raisedTertiaryWhite, .ghostPrimary, .ghostDanger, .applePayWhite:
                EmptyView()
            }
        }
        
        @ViewBuilder
        var backgroundHighlightedGradient: some View {
            switch self {
            case .raisedPrimary, .raisedDanger, .applePay:
                gradientWith(.white.opacity(0.44),
                             .white.opacity(0.0))
            case .raisedTertiary, .raisedPrimaryWhite, .applePayWhite:
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
            case .raisedPrimaryWhite, .applePayWhite:
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
            case .raisedPrimaryWhite, .applePayWhite:
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
            case .raisedTertiary, .raisedTertiaryWhite, .applePayWhite:
                return .backgroundSuccess
            case .ghostPrimary, .ghostDanger, .applePay:
                return .clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .raisedPrimary, .raisedDanger:
                return .foregroundOnEmphasis
            case .raisedPrimaryWhite, .applePayWhite:
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
            case .raisedTertiaryWhite, .applePayWhite:
                return .brandWhite.opacity(0.32)
            case .ghostPrimary:
                return .foregroundAccent.opacity(0.48)
            case .ghostDanger:
                return .foregroundDanger.opacity(0.48)
            }
        }
        
        var textSuccessColor: Color {
            switch self {
            case .raisedPrimary, .raisedPrimaryWhite, .raisedDanger, .applePayWhite:
                return .foregroundOnEmphasis
            case .raisedTertiary, .raisedTertiaryWhite, .ghostPrimary, .ghostDanger, .applePay:
                return .foregroundSuccess
            }
        }
    }
}
