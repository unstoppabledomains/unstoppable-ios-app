//
//  ClearListBackground.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.08.2023.
//

import SwiftUI

struct ClearListBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
    }
}


extension View {
    func clearListBackground() -> some View {
        modifier(ClearListBackground())
    }
}

