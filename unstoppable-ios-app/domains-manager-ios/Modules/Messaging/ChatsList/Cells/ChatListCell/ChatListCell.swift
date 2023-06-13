//
//  ChatListCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import UIKit

final class ChatListCell: BaseListCollectionViewCell {

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var chatNameLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var lastMessageLabel: UILabel!
    @IBOutlet private weak var badgeView: UnreadMessagesBadgeView!
    
}

// MARK: - Open methods
extension ChatListCell {
    func setWith(configuration: ChatsListViewController.ChatUIConfiguration) {
        let chat = configuration.chat
        if case .private(let info) = chat.type,
           let pfpURL = info.otherUser.pfpURL {
            setAvatarFrom(url: pfpURL)
        } else {
            setAvatarFrom(url: chat.avatarURL)
        }
        
        let chatName = chatNameFrom(chat: chat)
        setNameText(chatName)
        badgeView.setUnreadMessagesCount(chat.unreadMessagesCount)

        if let lastMessage = chat.lastMessage {
            setTimeText(lastMessage.time)
            
            let lastMessageText = lastMessageTextFrom(message: lastMessage)
            setLastMessageText(lastMessageText)
        } else {
            setTimeText(nil)
            setLastMessageText("")
        }
    }
    
    func setWith(configuration: ChatsListViewController.ChannelUIConfiguration) {
        let channel = configuration.channel
        setAvatarFrom(url: channel.icon)
        setNameText(channel.name)
        badgeView.setUnreadMessagesCount(channel.unreadMessagesCount)
        
        if let lastMessage = channel.lastMessage {
            setTimeText(lastMessage.time)
            setLastMessageText(lastMessage.title)
        } else {
            setTimeText(nil)
            setLastMessageText("")
        }
    }
}

// MARK: - Private methods
private extension ChatListCell {
    func chatNameFrom(chat: MessagingChatDisplayInfo) -> String {
        switch chat.type {
        case .private(let otherUserDetails):
            return otherUserDetails.otherUser.displayName
        case .group(let groupDetails):
            #if DEBUG
            return "Group chat <Not-supported>" // <GROUP_CHAT>
            #else
            return ""
            #endif
        }
    }
    
    func lastMessageTextFrom(message: MessagingChatMessageDisplayInfo) -> String  {
        switch message.type {
        case .text(let description):
            return description.text
        }
    }
    
    func setNameText(_ text: String) {
        chatNameLabel.setAttributedTextWith(text: text,
                                            font: .currentFont(withSize: 16, weight: .medium),
                                            textColor: .foregroundDefault)
    }
    
    func setLastMessageText(_ text: String) {
        lastMessageLabel.setAttributedTextWith(text: text,
                                               font: .currentFont(withSize: 14, weight: .regular),
                                               textColor: .foregroundSecondary,
                                               lineHeight: 20,
                                               lineBreakMode: .byTruncatingTail)
    }
    
    func setTimeText(_ time: Date?) {
        var text = ""
        if let time {
            text = MessageDateFormatter.formatChannelDate(time)
        }

        timeLabel.setAttributedTextWith(text: text,
                                        font: .currentFont(withSize: 13, weight: .regular),
                                        textColor: .foregroundSecondary)
    }
    
    func setAvatarFrom(url: URL?) {
        avatarImageView.image = .domainSharePlaceholder
        if let avatarURL = url {
            Task {
                let image = await appContext.imageLoadingService.loadImage(from: .url(avatarURL), downsampleDescription: nil)
                self.avatarImageView.image = image
            }
        }
    }
}
