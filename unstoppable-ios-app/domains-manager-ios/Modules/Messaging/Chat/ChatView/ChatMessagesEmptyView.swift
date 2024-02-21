//
//  ChatMessagesEmptyView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct ChatMessagesEmptyView: View {
    
    let mode: Mode
    
    var body: some View {
        ChatCommonEmptyView(icon: .messageCircleIcon24,
                            title: String.Constants.messagingChatEmptyTitle.localized(),
                            subtitle: mode.message)
    }
}

extension ChatMessagesEmptyView {
    enum Mode {
        case chatEncrypted
        case chatUnEncrypted
        case cantContact
        case community
        
        var message: String {
            switch self {
            case .chatEncrypted:
                return String.Constants.messagingChatEmptyEncryptedMessage.localized()
            case .chatUnEncrypted:
                return String.Constants.messagingChatEmptyUnencryptedMessage.localized()
            case .cantContact:
                return String.Constants.messagingCantContactMessage.localized()
            case .community:
                return String.Constants.messagingCommunityEmptyMessage.localized()
            }
        }
    }
}

#Preview {
    ChatMessagesEmptyView(mode: .cantContact)
}
