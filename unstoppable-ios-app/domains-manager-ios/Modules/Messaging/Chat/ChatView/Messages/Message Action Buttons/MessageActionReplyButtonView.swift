//
//  MessageActionReplyButtonView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.02.2024.
//

import SwiftUI

struct MessageActionReplyButtonView: View {
    
    @EnvironmentObject var viewModel: ChatViewModel
    
    let message: MessagingChatMessageDisplayInfo
    
    var body: some View {
        if viewModel.isAbleToReply,
           !message.senderType.isThisUser {
            Button {
                viewModel.handleChatMessageAction(.reply(message))
            } label: {
                Label(String.Constants.reply.localized(), systemImage: "arrowshape.turn.up.left.fill")
            }
        }
    }
}

#Preview {
    MessageActionReplyButtonView(message: MockEntitiesFabric.Messaging.createTextMessage(text: "Hi", isThisUser: false))
}
