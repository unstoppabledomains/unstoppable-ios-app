//
//  OnAppearanceChange.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import SwiftUI

struct OnAppearanceChange: ViewModifier {
    @Binding var isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
    }
}

extension View {
    func onAppearanceChange(_ isVisible: Binding<Bool>) -> some View {
        modifier(OnAppearanceChange(isVisible: isVisible))
    }
}
