//
//  UDButtonStyle+ViewModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import SwiftUI

extension UDButtonStyle {
    struct SpecialStyleModifier: ViewModifier {
        
        let style: UDButtonStyle
        
        func body(content: Content) -> some View {
            switch style {
            case .large(let largeStyle):
                content
                    .modifier(LargeStyleSpecialModifier(largeStyle: largeStyle,
                                                        cornerRadius: style.cornerRadius))
            case .medium(let mediumStyle):
                content
                    .modifier(MediumStyleSpecialModifier(mediumStyle: mediumStyle,
                                                         cornerRadius: style.cornerRadius))
                
            case .small(let smallStyle):
                content
                    .modifier(SmallStyleSpecialModifier(smallStyle: smallStyle,
                                                        cornerRadius: style.cornerRadius))
            case .verySmall(let verySmallStyle):
                content
                    .modifier(VerySmallStyleSpecialModifier(verySmallStyle: verySmallStyle,
                                                            cornerRadius: style.cornerRadius))
            }
        }
    }
}

// MARK: - LargeStyleSpecialModifier
private extension UDButtonStyle {
    struct LargeStyleSpecialModifier: ViewModifier {
        
        let largeStyle: LargeStyle
        let cornerRadius: CGFloat
        
        func body(content: Content) -> some View {
            switch largeStyle {
            case .raisedPrimary:
                content
                    .shadow(color: Color.backgroundAccentEmphasis2, radius: 0, x: 0, y: 0)
                    .overlay {
                        rectangleOverlay(color: .white.opacity(0.3))
                            
                    }
            case .raisedPrimaryWhite:
                content
                    .overlay {
                        rectangleOverlay(color: .black.opacity(0.12))
                    }
            case .raisedDanger:
                content
                    .shadow(color: Color.backgroundDangerEmphasis2, radius: 0, x: 0, y: 0)
                    .overlay {
                        rectangleOverlay(color: .white.opacity(0.3))
                        
                    }
            case .raisedTertiary:
                content
                    .shadow(color: Color.borderDefault, radius: 0, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.06), radius: 2.5, x: 0, y: 5)
                    .overlay {
                        rectangleOverlay(color: .white.opacity(0.08))
                    }
            case .raisedTertiaryWhite:
                content
                    .overlay {
                        rectangleOverlay(color: .white.opacity(0.12))
                    }
            case .applePay:
                content
                    .shadow(color: .black, radius: 0, x: 0, y: 0)
                    .overlay {
                        rectangleOverlay(color: .white.opacity(0.3))
                    }
            case .applePayWhite:
                content
                    .shadow(color: .black, radius: 0, x: 0, y: 0)
                    .overlay {
                        rectangleOverlay(color: .black.opacity(0.12))
                    }
            case .ghostPrimary, .ghostDanger:
                content
            }
        }
        
        @ViewBuilder
        private func rectangleOverlay(color: Color) -> some View {
            RoundedRectangle(cornerRadius: cornerRadius)
                .inset(by: 0.5)
                .stroke(color, lineWidth: 1)
        }
    }
}

// MARK: - MediumStyleSpecialModifier
private extension UDButtonStyle {
    struct MediumStyleSpecialModifier: ViewModifier {
        
        let mediumStyle: MediumStyle
        let cornerRadius: CGFloat
        
        func body(content: Content) -> some View {
            switch mediumStyle {
            case .raisedPrimary:
                content
                    .shadow(color: Color.backgroundAccentEmphasis2, radius: 0, x: 0, y: 0)
                    .overlay(rectangleOverlay(color: .white.opacity(0.3)))
            case .raisedTertiary:
                content
                    .shadow(color: Color.borderDefault, radius: 0, x: 0, y: 0)
                
                    .shadow(color: .black.opacity(0.06), radius: 2.5, x: 0, y: 5)
            case .raisedTertiaryWhite:
                content
                    .overlay(rectangleOverlay(color: .white.opacity(0.12)))
            case .ghostPrimary, .ghostPrimaryWhite, .ghostTertiary, .ghostTertiaryWhite, .raisedPrimaryWhite:
                content
            }
        }
        
        @ViewBuilder
        private func rectangleOverlay(color: Color) -> some View {
            RoundedRectangle(cornerRadius: cornerRadius)
                .inset(by: 0.5)
                .stroke(color, lineWidth: 1)
        }
    }
}

// MARK: - SmallStyleSpecialModifier
private extension UDButtonStyle {
    struct SmallStyleSpecialModifier: ViewModifier {
        
        let smallStyle: SmallStyle
        let cornerRadius: CGFloat
        
        func body(content: Content) -> some View {
            switch smallStyle {
            case .raisedPrimary:
                content
                    .shadow(color: Color.backgroundAccentEmphasis2, radius: 0, x: 0, y: 0)
                    .overlay(rectangleOverlay(color: .white.opacity(0.3)))
            case .raisedTertiary:
                content
                    .shadow(color: Color.borderDefault, radius: 0, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.06), radius: 2.5, x: 0, y: 5)
            default:
                content
            }
        }
        
        @ViewBuilder
        private func rectangleOverlay(color: Color) -> some View {
            RoundedRectangle(cornerRadius: cornerRadius)
                .inset(by: 0.5)
                .stroke(color, lineWidth: 1)
        }
    }
}

// MARK: - VerySmallStyleSpecialModifier
private extension UDButtonStyle {
    struct VerySmallStyleSpecialModifier: ViewModifier {
        
        let verySmallStyle: VerySmallStyle
        let cornerRadius: CGFloat
        
        func body(content: Content) -> some View {
            content
        }
    }
}
