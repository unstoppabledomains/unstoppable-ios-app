//
//  ChatMentionSuggestionRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.02.2024.
//

import SwiftUI

struct ChatMentionSuggestionRowView: View {
    
    let user: MessagingChatUserDisplayInfo
    
    @State private var avatar: UIImage?
    
    var body: some View {
        HStack(spacing: 12) {
            avatarView()
            titleView()
          
            Spacer()
        }
        .frame(height: 36)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension ChatMentionSuggestionRowView {
    func onAppear() {
        loadAvatar()
    }
    
    func loadAvatar() {
        Task {
            let imageLoader = MessagingChatUserDisplayInfoImageLoader.shared

            for await image in imageLoader.getLatestProfileImage(for: user) {
                avatar = image
            }
        }
    }
    
    @ViewBuilder
    func avatarView() -> some View {
        UIImageBridgeView(image: avatar)
            .squareFrame(24)
            .clipShape(Circle())
    }
    
    @ViewBuilder
    func titleView() -> some View {
        Text(user.displayName)
            .font(.currentFont(size: 17, weight: .semibold))
            .lineLimit(1)
    }
}

#Preview {
    ChatMentionSuggestionRowView(user: MockEntitiesFabric.Messaging.messagingChatUserDisplayInfo(withPFP: true))
}
