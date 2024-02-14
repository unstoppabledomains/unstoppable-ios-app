//
//  TabBarVisibleModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.01.2024.
//

import SwiftUI

struct TabBarVisibleModifier: ViewModifier {
    
    let visible: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbar(visible ? .visible : .hidden, for: .tabBar)
    }
}

extension View {
    func tabBarVisible(_ visible: Bool) -> some View {
        modifier(TabBarVisibleModifier(visible: visible))
    }
}
