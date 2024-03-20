//
//  NavigationTopSafeAreaOffset.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct NavigationTopSafeAreaOffsetViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, content: {
                Color.clear
                    .frame(height: 44)
            })
    }
}
extension View{
    func addNavigationTopSafeAreaOffset() -> some View{
        self.modifier(NavigationTopSafeAreaOffsetViewModifier())
    }
}
