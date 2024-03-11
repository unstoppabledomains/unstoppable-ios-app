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
        case .large, .medium, .small, .verySmall:
            return 12
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
