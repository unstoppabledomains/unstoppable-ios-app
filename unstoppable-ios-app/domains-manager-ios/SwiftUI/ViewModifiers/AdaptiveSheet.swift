//
//  AdaptiveSheet.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.08.2023.
//

import SwiftUI

struct AdaptiveSheet: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.medium, .large])
        } else {
            content
        }
    }
}

extension View {
    func adaptiveSheet() -> some View {
        modifier(AdaptiveSheet())
    }
}
