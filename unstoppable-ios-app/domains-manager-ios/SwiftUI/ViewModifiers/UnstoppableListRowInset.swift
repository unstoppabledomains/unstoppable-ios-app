//
//  UnstoppableListRowInset.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.08.2023.
//

import SwiftUI

struct UnstoppableListRowInset: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}


extension View {
    func unstoppableListRowInset() -> some View {
        modifier(UnstoppableListRowInset())
    }
}

