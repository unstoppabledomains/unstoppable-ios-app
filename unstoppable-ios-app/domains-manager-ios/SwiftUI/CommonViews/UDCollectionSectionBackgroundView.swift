//
//  UDCollectionSectionBackgroundView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import SwiftUI

struct UDCollectionSectionBackgroundView<Content: View>: View {
    
    let content: ()->(Content)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundOverlay)
            content()
//            .padding()
        }
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 8)
        .padding()
    }
}

#Preview {
    UDCollectionSectionBackgroundView(content: {
        Text("Hello")
    })
}
