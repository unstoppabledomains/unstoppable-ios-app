//
//  ChatMentionSuggestionsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.02.2024.
//

import SwiftUI

struct ChatMentionSuggestionsView: View {
    
    let suggestingUsers: [MessagingChatUserDisplayInfo]
    let selectionCallback: (MessagingChatUserDisplayInfo)->()
    
    private let maximumNumberOfVisibleSuggestingUsers = 6
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(suggestingUsersToDisplay, 
                    id: \.wallet) { user in
                selectableRowViewFor(user: user)
            }
        }
        .padding()
        .background(Color.backgroundDefault)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Private methods
private extension ChatMentionSuggestionsView {
    var suggestingUsersToDisplay: [MessagingChatUserDisplayInfo] {
        Array(suggestingUsers.prefix(maximumNumberOfVisibleSuggestingUsers))
    }
    
    @ViewBuilder
    func selectableRowViewFor(user: MessagingChatUserDisplayInfo) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            selectionCallback(user)
        } label: {
            ChatMentionSuggestionRowView(user: user)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChatMentionSuggestionsView(suggestingUsers: MockEntitiesFabric.Messaging.suggestingGroupChatMembersDisplayInfo(),
                               selectionCallback: { _ in })
}
