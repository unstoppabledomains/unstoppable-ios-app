//
//  NavBarVisibleModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.12.2023.
//

import SwiftUI

struct NavBarVisibleModifier: ViewModifier {
    
    let visible: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbarBackground(visible ? .visible : .hidden, for: .navigationBar)
    }
}

extension View {
    func navBarVisible(_ visible: Bool) -> some View {
        modifier(NavBarVisibleModifier(visible: visible))
    }
}
