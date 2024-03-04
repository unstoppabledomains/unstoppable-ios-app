//
//  SelectableChatRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct SelectableChatRowView: View, ViewAnalyticsLogger {
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    let chat: MessagingChatDisplayInfo
    let chatSelectedCallback: (MessagingChatDisplayInfo)->()
    var joinCommunityCallback: ((MessagingChatDisplayInfo)->())? = nil
    
    var body: some View {
        switch chat.type {
        case .private, .group:
            chatDefaultSelectableRowView(chat: chat)
        case .community(let details):
            if details.isJoined {
                chatDefaultSelectableRowView(chat: chat)
            } else {
                ChatListChatRowView(chat: chat, joinCommunityCallback: {
                    joinCommunityCallback?(chat)
                })
                .padding(.init(horizontal: 12))
            }
        }
    }
}

// MARK: - Private methods
private extension SelectableChatRowView {
    @ViewBuilder
    func chatDefaultSelectableRowView(chat: MessagingChatDisplayInfo) -> some View {
        UDCollectionListRowButton(content: {
            ChatListChatRowView(chat: chat)
                .udListItemInCollectionButtonPadding()
        }, callback: {
            UDVibration.buttonTap.vibrate()
            switch chat.type {
            case .private, .group:
                logButtonPressedAnalyticEvents(button: .chatInList)
            case .community:
                logButtonPressedAnalyticEvents(button: .communityInList)
            }
            chatSelectedCallback(chat)
        })
    }
}

#Preview {
    SelectableChatRowView(chat: MockEntitiesFabric.Messaging.mockPrivateChat(),
                          chatSelectedCallback: { _ in })
}
