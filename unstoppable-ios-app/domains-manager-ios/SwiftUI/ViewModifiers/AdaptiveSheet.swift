//
//  AdaptiveSheet.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.08.2023.
//

import SwiftUI

struct AdaptiveSheet: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationDetents([.medium, .large])
    }
}

extension View {
    func adaptiveSheet() -> some View {
        modifier(AdaptiveSheet())
    }
}
