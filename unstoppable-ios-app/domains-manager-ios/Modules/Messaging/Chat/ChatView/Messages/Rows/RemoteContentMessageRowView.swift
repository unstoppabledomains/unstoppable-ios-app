//
//  RemoteContentMessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct RemoteContentMessageRowView: View {
    
    let sender: MessagingChatSender

    var body: some View {
        ProgressView()
            .squareFrame(50)
            .contextMenu {
                if !sender.isThisUser {
                    MessageActionBlockUserButtonView(sender: sender)
                }
            }
    }
}

#Preview {
    RemoteContentMessageRowView(sender: MockEntitiesFabric.Messaging.chatSenderFor(isThisUser: false))
}
