//
//  PresentationStyleCheckerModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

struct PresentationStyleCheckerModifier: ViewModifier {
    
    @Binding var viewPresentationStyle: ViewPresentationStyle
    
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .onAppear(perform: {
                    if proxy.safeAreaInsets.top == 0 {
                        viewPresentationStyle = .sheet
                    } else {
                        viewPresentationStyle = .fullScreen
                    }
                })
        }
    }
}

extension View {
    func presentationStyleChecker(viewPresentationStyle: Binding<ViewPresentationStyle>) -> some View {
        modifier(PresentationStyleCheckerModifier(viewPresentationStyle: viewPresentationStyle))
    }
}

enum ViewPresentationStyle {
    case fullScreen, sheet
}
