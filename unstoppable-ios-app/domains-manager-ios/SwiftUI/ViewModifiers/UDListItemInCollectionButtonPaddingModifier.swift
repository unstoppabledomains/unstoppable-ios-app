//
//  UDListItemInCollectionButtonPaddingModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct UDListItemInCollectionButtonPaddingModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .padding(.init(horizontal: 12, vertical: 8))
    }
    
}

extension View {
    func udListItemInCollectionButtonPadding() -> some View {
        self.modifier(UDListItemInCollectionButtonPaddingModifier())
    }
}
