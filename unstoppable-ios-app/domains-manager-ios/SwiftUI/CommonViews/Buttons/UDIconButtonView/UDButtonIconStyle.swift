//
//  UDButtonIconStyle.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 20.11.2023.
//

import SwiftUI

enum UDButtonIconStyle {
    case circle(size: CircleSize, style: CircleStyle)
    case rectangle(size: RectangleSize, style: RectangleStyle)
    
    var iconSize: CGFloat {
        switch self {
        case .circle(let size, _):
            return size.iconSize
        case .rectangle(let size, _):
            return size.iconSize
        }
    }
    
    var iconColor: Color {
        switch self {
        case .circle(_, let style):
            return style.iconColor
        case .rectangle(_, let style):
            return style.iconColor
        }
    }
    var iconDisabledColor: Color {
        switch self {
        case .circle(_, let style):
            return style.iconDisabledColor
        case .rectangle(_, let style):
            return style.iconDisabledColor
        }
    }
}

extension UDButtonIconStyle {
    enum CircleSize {
        case small, medium
        
        var backgroundSize: CGFloat {
            switch self {
            case .small:
                return 32
            case .medium:
                return 40
            }
        }
        var iconSize: CGFloat {
            switch self {
            case .small:
                return 16
            case .medium:
                return 20
            }
        }
    }
    
    enum CircleStyle: String, CaseIterable {
        case raisedPrimary, raisedPrimaryWhite
        case raisedTertiary, raisedTertiaryWhite
        
        var backgroundIdleColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccentEmphasis
            case .raisedPrimaryWhite:
                return .brandWhite
            case .raisedTertiary:
                return .backgroundMuted2
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.16)
            }
        }
        
        var backgroundHighlightedColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccentEmphasis2
            case .raisedPrimaryWhite:
                return .brandWhite.opacity(0.64)
            case .raisedTertiary:
                return .backgroundMuted
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.24)
            }
        }
        
        var backgroundDisabledColor: Color {
            switch self {
            case .raisedPrimary:
                return .backgroundAccent
            case .raisedPrimaryWhite:
                return .brandWhite.opacity(0.16)
            case .raisedTertiary:
                return .backgroundSubtle
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.08)
            }
        }
        
        var iconColor: Color {
            switch self {
            case .raisedPrimary:
                return .foregroundOnEmphasis
            case .raisedPrimaryWhite:
                return .black
            case .raisedTertiary:
                return .foregroundDefault
            case .raisedTertiaryWhite:
                return .brandWhite
            }
        }
        
        var iconDisabledColor: Color {
            switch self {
            case .raisedPrimary:
                return .foregroundOnEmphasisOpacity
            case .raisedPrimaryWhite:
                return .black
            case .raisedTertiary:
                return .foregroundMuted
            case .raisedTertiaryWhite:
                return .brandWhite.opacity(0.32)
            }
        }
        
    }
}

extension UDButtonIconStyle {
    enum RectangleSize {
        case small
        
        var backgroundSize: CGFloat {
            switch self {
            case .small:
                return 28
            }
        }
        var cornerRadius: CGFloat {
            switch self {
            case .small:
                return 8
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small:
                return 16
            }
        }
    }
    
    enum RectangleStyle: String, CaseIterable {
        case raisedTertiary
        
        var backgroundIdleColor: Color {
            switch self {
            case .raisedTertiary:
                return .backgroundSubtle
            }
        }
        
        var backgroundHighlightedColor: Color {
            switch self {
            case .raisedTertiary:
                return .backgroundMuted
            }
        }
        
        var backgroundDisabledColor: Color {
            switch self {
            case .raisedTertiary:
                return .backgroundSubtle
            }
        }
        
        var iconColor: Color {
            switch self {
            case .raisedTertiary:
                return .foregroundDefault
            }
        }
        
        var iconDisabledColor: Color {
            switch self {
            case .raisedTertiary:
                return .foregroundMuted
            }
        }
        
        var borderColor: Color {
            switch self {
            case .raisedTertiary:
                return .borderMuted
            }
        }
    }
}
