//
//  ChatCommonEmptyView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct ChatCommonEmptyView: View {
    
    let icon: Image
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            icon
                .resizable()
                .squareFrame(32)
            VStack(spacing: 8) {
                Text(title)
                    .font(.currentFont(size: 20, weight: .bold))
                Text(subtitle)
                    .font(.currentFont(size: 16))
            }
            .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.foregroundSecondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ChatCommonEmptyView(icon: .messagesIcon,
                        title: "Title",
                        subtitle: "Subtitle")
}
