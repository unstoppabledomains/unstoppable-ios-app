//
//  ChatListChannelRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct ChatListChannelRowView: View {
    @Environment(\.imageLoadingService) private var imageLoadingService
    let channel: MessagingNewsChannel
    
    @State private var icon: UIImage?
    private let iconSize: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 16) {
            avatarsView()
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(channel.name)
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
private extension ChatListChannelRowView {
    func onAppear() {
        setAvatar()
    }
    
    func setAvatar() {
        setAvatarFrom(url: channel.icon, name: channel.name)
    }
    
    func setAvatarFrom(url: URL?, name: String) {
        icon = nil
       
        Task {
            icon = await imageLoadingService.loadImage(from: .initials(name,
                                                                       size: .default,
                                                                       style: .accent),
                                                       downsampleDescription: nil)
            if let avatarURL = url {
                if let image = await appContext.imageLoadingService.loadImage(from: .url(avatarURL), downsampleDescription: .icon) {
                    icon = image
                }
            }
        }
    }
    
    @ViewBuilder
    func avatarsView() -> some View {
        UIImageBridgeView(image: icon)
        .squareFrame(iconSize)
        .clipShape(Circle())
    }
    
    @ViewBuilder
    func subtitleView() -> some View {
        if let lastMessage = channel.lastMessage {
            Text(lastMessage.message)
                .lineLimit(2)
                .foregroundStyle(Color.foregroundSecondary)
                .font(.currentFont(size: 14))
        }
    }
    
    func lastMessageTextFrom(message: MessagingNewsChannelFeed) -> String  {
        if message.title.trimmedSpaces.isEmpty {
            return message.message
        } else {
            return message.title
        }
    }
    
    @ViewBuilder
    func timeView() -> some View {
        if let lastMessage = channel.lastMessage {
            Text(MessageDateFormatter.formatChannelDate(lastMessage.time))
                .font(.currentFont(size: 13))
                .foregroundStyle(Color.foregroundSecondary)
        }
    }
}

#Preview {
    ChatListChannelRowView(channel: MockEntitiesFabric.Messaging.mockChannel(name: "Preview"))
}
