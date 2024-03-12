//
//  UDButtonStyle+VerySmall.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import SwiftUI

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
