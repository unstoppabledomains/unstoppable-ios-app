//
//  SideInsets.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 21.08.2023.
//

import SwiftUI

struct SideInsets: ViewModifier {
    let padding: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding))
    }
}

extension View {
    func sideInsets(_ padding: CGFloat) -> some View {
        modifier(SideInsets(padding: padding))
    }
}

