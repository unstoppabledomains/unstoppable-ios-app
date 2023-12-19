//
//  UDCollectionSectionBackgroundView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import SwiftUI

struct UDCollectionSectionBackgroundView<Content: View>: View {
    
    var backgroundColor: Color = .backgroundOverlay
    var withShadow: Bool = false
    let content: ()->(Content)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
            content()
        }
        .backgroundShadow(needed: withShadow)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 8)
    }
    
    init(backgroundColor: Color = .backgroundOverlay,
         withShadow: Bool = false,
         @ViewBuilder content: @escaping () -> Content) {
        self.backgroundColor = backgroundColor
        self.withShadow = withShadow
        self.content = content
    }
    
}


private struct UDCollectionSectionBackgroundViewShadow: ViewModifier {
    
    let needed: Bool
    
    func body(content: Content) -> some View {
        if needed {
            content
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 8)
        } else {
            content
        }
    }
}

private extension View {
    func backgroundShadow(needed: Bool) -> some View {
        modifier(UDCollectionSectionBackgroundViewShadow(needed: needed))
    }
}



#Preview {
    UDCollectionSectionBackgroundView(content: {
        Text("Hello")
    })
}
