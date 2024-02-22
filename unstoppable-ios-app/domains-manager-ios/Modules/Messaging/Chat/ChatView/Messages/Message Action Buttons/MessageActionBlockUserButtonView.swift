//
//  MessageActionBlockUserButtonView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.02.2024.
//

import SwiftUI

struct MessageActionBlockUserButtonView: View {
    
    @EnvironmentObject var viewModel: ChatViewModel

    let sender: MessagingChatSender
    
    var body: some View {
        Button(role: .destructive) {
            viewModel.handleChatMessageAction(.blockUserInGroup(sender.userDisplayInfo))
        } label: {
            Label(String.Constants.blockUser.localized(), systemImage: "xmark.circle")
        }
    }
}

#Preview {
    MessageActionBlockUserButtonView(sender: MockEntitiesFabric.Messaging.chatSenderFor(isThisUser: false))
}
