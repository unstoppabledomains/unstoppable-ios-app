//
//  UDSubtitleText.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import Foundation
import SwiftUI

struct UDSubtitleText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.currentFont(size: 16))
            .foregroundStyle(Color.foregroundSecondary)
    }
}

extension View {
    func subtitleText() -> some View {
        modifier(UDSubtitleText())
    }
}

