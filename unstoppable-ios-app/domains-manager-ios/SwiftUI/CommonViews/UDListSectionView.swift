//
//  UDListSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.02.2024.
//

import SwiftUI

struct UDListSectionView<Content: View>: View {
    
    let content: ()->(Content)
    
    var body: some View {
        Section {
            content()
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(Color.backgroundOverlay)
        }
    }
}

