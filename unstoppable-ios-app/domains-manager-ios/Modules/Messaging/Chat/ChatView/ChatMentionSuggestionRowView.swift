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
        let userInfo = user
        Task {
            let name = userInfo.displayName
            avatar = await appContext.imageLoadingService.loadImage(from: .initials(name,
                                                                                             size: .default,
                                                                                             style: .accent),
                                                                             downsampleDescription: nil)
            
            if let image = await appContext.imageLoadingService.loadImage(from: .messagingUserPFPOrInitials(userInfo,
                                                                                                         size: .default),
                                                                          downsampleDescription: .icon) {
                avatar = image
            }
        }
    }
    
    @ViewBuilder
    func avatarView() -> some View {
        UIImageBridgeView(image: avatar,
                          width: 20,
                          height: 20)
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
