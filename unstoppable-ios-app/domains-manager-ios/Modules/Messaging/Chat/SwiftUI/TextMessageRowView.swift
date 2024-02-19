//
//  TextMessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct TextMessageRowView: View {
    
    let info: MessagingChatMessageTextTypeDisplayInfo
    let isThisUser: Bool
    let isFailed: Bool
    
    var body: some View {
        Text(info.text)
            .padding(.init(horizontal: 12))
            .padding(.init(vertical: 6))
            .foregroundStyle(foregroundColor)
            .background(isThisUser ? Color.backgroundAccentEmphasis : Color.backgroundMuted2)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Private methods
private extension TextMessageRowView {
    var foregroundColor: Color {
        if isFailed {
            return .foregroundOnEmphasisOpacity
        }
        return isThisUser ? .foregroundOnEmphasis : .foregroundDefault
    }
}

#Preview {
    TextMessageRowView(info: .init(text: "Hello world"),
                       isThisUser: true,
                       isFailed: true)
}
