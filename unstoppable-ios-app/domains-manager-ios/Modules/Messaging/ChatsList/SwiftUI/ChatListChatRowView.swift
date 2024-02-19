//
//  ChatListChatRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct ChatListChatRowView: View {
    
    let chat: MessagingChatDisplayInfo
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    ChatListChatRowView(chat: MockEntitiesFabric.Messaging.mockPrivateChat())
}
