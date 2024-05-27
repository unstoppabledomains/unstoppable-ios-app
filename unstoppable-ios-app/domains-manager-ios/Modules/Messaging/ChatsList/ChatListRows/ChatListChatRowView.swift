//
//  ChatListChatRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct ChatListChatRowView: View, ViewAnalyticsLogger {
    
    @Environment(\.imageLoadingService) private var imageLoadingService
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    let chat: MessagingChatDisplayInfo
    var joinCommunityCallback: EmptyCallback? = nil
    
    @State private var icon: UIImage?
    @State private var asyncSubtitle: String?
    private let iconSize: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 16) {
            avatarsView()
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(currentTitle)
                        .font(.currentFont(size: 16, weight: .medium))
                        .foregroundStyle(Color.foregroundDefault)
                    subtitleView()
                }
                Spacer()
                trailingView()
            }
        }
        .frame(height: 52)
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
    func avatarsView() -> some View {
        switch chat.type {
        case .private, .community:
            iconView()
                .clipShape(Circle())
        case .group:
            iconView()
        }
    }
    
    @ViewBuilder
    func iconView() -> some View {
        UIImageBridgeView(image: icon)
        .squareFrame(iconSize)
    }
    
    var currentTitle: String {
        switch chat.type {
        case .private(let messagingPrivateChatDetails):
            return messagingPrivateChatDetails.otherUser.displayName
        case .group(let messagingGroupChatDetails):
            return messagingGroupChatDetails.displayName
        case .community(let messagingCommunitiesChatDetails):
            return messagingCommunitiesChatDetails.displayName
        }
    }
    
    @ViewBuilder
    func subtitleView() -> some View {
        if let subtitle = getSubtitleText() {
            Text(subtitle)
                .lineLimit(2)
                .foregroundStyle(Color.foregroundSecondary)
                .font(.currentFont(size: 14))
        }
    }
    
    func getSubtitleText() -> String? {
        if let lastMessage = chat.lastMessage {
            return lastMessageTextFrom(message: lastMessage)
        } else if case .community(let details) = chat.type,
                  !details.isJoined {
            switch details.type {
            case .badge(let badge):
                Task {
                    if let holders = try? await BadgeHoldersFetcher.shared.getNumberOfHoldersFor(badge: badge) {
                        let holdersKsString = holders.asFormattedKsString
                        asyncSubtitle = String.Constants.pluralNHolders.localized(holdersKsString, holders)
                    }
                }
                return asyncSubtitle
            }
        }
        return nil
    }
    
    func lastMessageTextFrom(message: MessagingChatMessageDisplayInfo) -> String  {
        message.type.getContentDescriptionText()
    }
    
    @ViewBuilder
    func trailingView() -> some View {
        if case .community(let details) = chat.type,
           !details.isJoined {
            joinCommunityButtonView(messagingCommunitiesChatDetails: details)
        } else {
            timeView()
        }
    }
    
    @ViewBuilder
    func timeView() -> some View {
        VStack(spacing: 4) {
            if let lastMessage = chat.lastMessage {
                Text(MessageDateFormatter.formatChannelDate(lastMessage.time))
                    .font(.currentFont(size: 13))
                    .foregroundStyle(Color.foregroundSecondary)
            }
            UnreadMessagesCounterView(unreadMessages: chat.unreadMessagesCount)
        }
    }
    
    @ViewBuilder
    func joinCommunityButtonView(messagingCommunitiesChatDetails: MessagingCommunitiesChatDetails) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: .joinCommunity,
                                           parameters: [.communityName: messagingCommunitiesChatDetails.displayName])
            joinCommunityCallback?()
        } label: {
            Text(String.Constants.join.localized())
                .font(.currentFont(size: 14, weight: .medium))
                .foregroundStyle(Color.foregroundOnEmphasis)
                .frame(height: 20)
                .padding(.init(vertical: 6))
                .padding(.init(horizontal: 12))
                .background(Color.backgroundAccentEmphasis)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct UnreadMessagesCounterView: View {
    
    let unreadMessages: Int
    
    var body: some View {
        if unreadMessages > 0 {
            ZStack {
                Text("\(unreadMessages)")
                    .font(.currentFont(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.init(horizontal: 5))
            }
            .frame(height: 16)
            .background(Color.foregroundAccent)
            .modifier(ClipShapeModifier(unreadMessages: unreadMessages))
        }
    }
    
    private struct ClipShapeModifier: ViewModifier {
        let unreadMessages: Int

        func body(content: Content) -> some View {
            if unreadMessages > 9 {
                content
                    .clipShape(Capsule())
            } else {
                content
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    ChatListChatRowView(chat: MockEntitiesFabric.Messaging.mockPrivateChat())
}

private actor BadgeHoldersFetcher {
    
    private var cache: [String : Int] = [:]
    private var ongoingTasks: [String : Task<Int, Error>] = [:]
    private let requestsLimitController = RequestsLimitController(requestLimit: 20, timeInterval: 60) // 20 requests per 60 seconds

    static let shared = BadgeHoldersFetcher()
    
    func getNumberOfHoldersFor(badge: BadgesInfo.BadgeInfo) async throws -> Int {
        let code = badge.code
        
        if let cachedValue = cache[code] {
            return cachedValue
        } else if let ongoingTask = ongoingTasks[code] {
            return try await ongoingTask.value
        } else {
            await requestsLimitController.acquirePermission()

            let task = Task {
                let badgeInfo = try await NetworkService().fetchBadgeDetailedInfo(for: badge)
                return badgeInfo.usage.holders
            }
            
            self.ongoingTasks[code] = task
            let value = try await task.value
            self.cache[code] = value
            self.ongoingTasks[code] = nil
            return value
        }
    }
    
}
