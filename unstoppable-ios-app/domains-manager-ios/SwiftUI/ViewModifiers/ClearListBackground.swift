//
//  ClearListBackground.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.08.2023.
//

import SwiftUI

struct ClearListBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            return content.scrollContentBackground(.hidden)
        } else {
            UITableView.appearance().backgroundColor = .clear
            return content
        }
    }
}


extension View {
    func clearListBackground() -> some View {
        modifier(ClearListBackground())
    }
}

