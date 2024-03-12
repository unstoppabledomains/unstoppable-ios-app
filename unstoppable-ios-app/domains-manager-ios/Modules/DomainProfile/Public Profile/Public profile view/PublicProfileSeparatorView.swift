//
//  PublicProfileSeparatorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct PublicProfileSeparatorView: View {
    var body: some View {
        LineView(direction: .horizontal, dashed: true)
            .foregroundColor(.white)
            .opacity(0.08)
            .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }
}

#Preview {
    PublicProfileSeparatorView()
}
