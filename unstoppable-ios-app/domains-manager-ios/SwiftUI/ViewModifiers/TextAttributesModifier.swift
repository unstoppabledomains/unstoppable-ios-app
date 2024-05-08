//
//  TextAttributesModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.05.2024.
//

import SwiftUI

struct TextAttributesModifier: ViewModifier {
    let color: Color
    let fontSize: CGFloat
    let fontWeight: UIFont.Weight
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(color)
            .font(.currentFont(size: fontSize, weight: fontWeight))
    }
}

extension View {
    func textAttributes(color: Color,
                        fontSize: CGFloat,
                        fontWeight: UIFont.Weight = .regular) -> some View {
        modifier(TextAttributesModifier(color: color,
                                        fontSize: fontSize,
                                        fontWeight: fontWeight))
    }
}

