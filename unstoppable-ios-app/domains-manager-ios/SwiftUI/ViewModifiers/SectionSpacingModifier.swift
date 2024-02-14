//
//  SectionSpacingModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.02.2024.
//

import SwiftUI

struct SectionSpacingModifier: ViewModifier {
    
    let spacing: CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .listSectionSpacing(spacing)
        } else {
            content
        }
    }
    
    init(spacing: CGFloat) {
        self.spacing = spacing
    }
}


extension View {
    func sectionSpacing(_ spacing: CGFloat) -> some View {
        modifier(SectionSpacingModifier(spacing: spacing))
    }
}
