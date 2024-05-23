//
//  PublicProfileSeparatorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct PublicProfileSeparatorView: View {
    
    var verticalPadding: CGFloat = 8
    
    var body: some View {
        LineView(direction: .horizontal, dashed: true)
            .foregroundColor(.white)
            .opacity(0.08)
            .padding(.vertical, verticalPadding)
    }
}

#Preview {
    PublicProfileSeparatorView()
}
