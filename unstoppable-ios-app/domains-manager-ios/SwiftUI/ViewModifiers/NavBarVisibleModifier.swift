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
        if #available(iOS 16.0, *) {
            content
                .toolbarBackground(visible ? .visible : .hidden, for: .navigationBar)
        } else {
            content
        }
    }
}

extension View {
    func navBarVisible(_ visible: Bool) -> some View {
        modifier(NavBarVisibleModifier(visible: visible))
    }
}
