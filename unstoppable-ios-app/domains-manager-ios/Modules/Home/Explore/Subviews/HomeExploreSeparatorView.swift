//
//  HomeExploreSeparatorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct HomeExploreSeparatorView: View {
    var body: some View {
        LineView(direction: .horizontal)
            .foregroundStyle(Color.white.opacity(0.08))
            .shadow(color: Color.foregroundOnEmphasis2, radius: 0, x: 0, y: -1)
    }
}

#Preview {
    HomeExploreSeparatorView()
}
