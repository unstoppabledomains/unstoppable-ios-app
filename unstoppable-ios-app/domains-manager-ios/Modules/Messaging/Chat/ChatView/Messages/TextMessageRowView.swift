//
//  TextMessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct TextMessageRowView: View {
    
    @EnvironmentObject var viewModel: ChatViewModel

    let info: MessagingChatMessageTextTypeDisplayInfo
    let sender: MessagingChatSender
    let isFailed: Bool
    
    var body: some View {
        Text(info.text)
            .padding(.init(horizontal: 12))
            .padding(.init(vertical: 6))
            .foregroundStyle(foregroundColor)
            .background(sender.isThisUser ? Color.backgroundAccentEmphasis : Color.backgroundMuted2)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contextMenu {
                Button {
                    viewModel.handleChatMessageAction(.copyText(info.text))
                } label: {
                    Label(String.Constants.copy.localized(), systemImage: "doc.on.doc")
                }
                
                if !sender.isThisUser {
                    Divider()
                    MessageActionBlockUserButtonView(sender: sender)
                }
            }
    }
}

// MARK: - Private methods
private extension TextMessageRowView {
    var foregroundColor: Color {
        if isFailed {
            return .foregroundOnEmphasisOpacity
        }
        return sender.isThisUser ? .foregroundOnEmphasis : .foregroundDefault
    }
}

#Preview {
    TextMessageRowView(info: .init(text: "Hello world"),
                       sender: MockEntitiesFabric.Messaging.chatSenderFor(isThisUser: false),
                       isFailed: true)
}
