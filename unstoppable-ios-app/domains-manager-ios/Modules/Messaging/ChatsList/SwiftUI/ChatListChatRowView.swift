//
//  ChatListChatRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct ChatListChatRowView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService
    let chat: MessagingChatDisplayInfo
    
    @State private var icon: UIImage?
    private let iconSize: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 16) {
            iconView()
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(currentTitle)
                        .font(.currentFont(size: 16, weight: .medium))
                        .foregroundStyle(Color.foregroundDefault)
                    subtitleView()
                }
                Spacer()
                timeView()
            }
        }
        .frame(height: 60)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension ChatListChatRowView {
    func onAppear() {
        setAvatar()
    }
    
    func setAvatar() {
        switch chat.type {
        case .private(let info):
            setAvatarFrom(url: info.otherUser.pfpURL, name: currentTitle)
        case .group(let details):
         
            Task {
                icon = await MessagingImageLoader.buildImageForGroupChatMembers(details.allMembers,
                                                                                                 iconSize: iconSize)
            }
        case .community(let details):
            setAvatarFrom(url: URL(string: details.displayIconUrl), 
                          name: currentTitle)
        }
    }
    
    func setAvatarFrom(url: URL?, name: String) {
        icon = nil
        
        @Sendable func setAvatarFromName() async {
            icon = await imageLoadingService.loadImage(from: .initials(name,
                                                                                                        size: .default,
                                                                                                        style: .accent),
                                                                                        downsampleDescription: nil)
        }
        
        Task {
            await setAvatarFromName()
            if let avatarURL = url {
                if let image = await appContext.imageLoadingService.loadImage(from: .url(avatarURL), downsampleDescription: .icon) {
                    icon = image
                }
            }
        }
    }
    
    @ViewBuilder
    func iconView() -> some View {
        UIImageBridgeView(image: icon,
                          width: iconSize,
                          height: iconSize)
        .squareFrame(iconSize)
        .clipShape(Circle())
    }
    
    var currentTitle: String {
        switch chat.type {
        case .private(let messagingPrivateChatDetails):
            let userInfo = messagingPrivateChatDetails.otherUser
            
            
            if userInfo.rrDomainName == nil {
                return userInfo.displayName
            } else {
                return userInfo.domainName ?? ""
            }
        case .group(let messagingGroupChatDetails):
            return messagingGroupChatDetails.displayName
        case .community(let messagingCommunitiesChatDetails):
            return messagingCommunitiesChatDetails.displayName
        }
    }
    
    @ViewBuilder
    func subtitleView() -> some View {
        if let lastMessage = chat.lastMessage {
            Text(lastMessageTextFrom(message: lastMessage))
                .lineLimit(2)
                .foregroundStyle(Color.foregroundSecondary)
                .font(.currentFont(size: 14))
        }
    }
    
    func lastMessageTextFrom(message: MessagingChatMessageDisplayInfo) -> String  {
        switch message.type {
        case .text(let description):
            return description.text
        case .imageBase64, .imageData:
            return String.Constants.photo.localized()
        case .unknown:
            return String.Constants.messageNotSupported.localized()
        case .remoteContent:
            return String.Constants.messagingRemoteContent.localized()
        case .reaction(let info):
            return info.content
        }
    }
    
    
    @ViewBuilder
    func timeView() -> some View {
        if let lastMessage = chat.lastMessage {
            Text(MessageDateFormatter.formatChannelDate(lastMessage.time))
                .font(.currentFont(size: 13))
                .foregroundStyle(Color.foregroundSecondary)
        }
    }
}

#Preview {
    ChatListChatRowView(chat: MockEntitiesFabric.Messaging.mockPrivateChat())
}
