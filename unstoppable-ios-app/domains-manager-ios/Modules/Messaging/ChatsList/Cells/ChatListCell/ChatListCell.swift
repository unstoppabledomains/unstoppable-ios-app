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
    @IBOutlet private weak var chevron: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        badgeView.setCounterLabel(hidden: true)
    }
    
}

// MARK: - Open methods
extension ChatListCell {
    func setWith(configuration: ChatsListViewController.ChatUIConfiguration) {
        let chat = configuration.chat
        let chatName = chatNameFrom(chat: chat)
        
        switch chat.type {
        case .private(let info):
            avatarImageView.layer.borderWidth = 1
            setAvatarFrom(url: info.otherUser.pfpURL, name: chatName)
        case .group(let details):
            avatarImageView.clipsToBounds = false
            avatarImageView.layer.borderWidth = 0
            Task { avatarImageView.image = await MessagingImageLoader.buildImageForGroupChatMembers(details.allMembers,
                                                                                                    iconSize: avatarImageView.bounds.width) }
        }
        
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
        chevron.isHidden = true
    }
    
    func setWith(configuration: ChatsListViewController.ChannelUIConfiguration) {
        let channel = configuration.channel
        let chatName = channel.name
        setNameText(chatName)
        setAvatarFrom(url: channel.icon, name: chatName)
        badgeView.setUnreadMessagesCount(channel.unreadMessagesCount)
        
        if let lastMessage = channel.lastMessage {
            setTimeText(lastMessage.time)
            if lastMessage.title.trimmedSpaces.isEmpty {
                setLastMessageText(lastMessage.message)
            } else {
                setLastMessageText(lastMessage.title)
            }
        } else {
            setTimeText(nil)
            setLastMessageText("")
        }
        chevron.isHidden = true
    }
    
    func setWith(configuration: ChatsListViewController.UserInfoUIConfiguration) {
        let userInfo = configuration.userInfo
        let chatName = chatNameFrom(userInfo: userInfo)
        setNameText(chatName)
        setAvatarFrom(url: userInfo.pfpURL, name: chatName)
        badgeView.setUnreadMessagesCount(0)

        setTimeText(nil)
        setLastMessageText("")
        chevron.isHidden = false
    }
}

// MARK: - Private methods
private extension ChatListCell {
    func chatNameFrom(chat: MessagingChatDisplayInfo) -> String {
        switch chat.type {
        case .private(let otherUserDetails):
            return chatNameFrom(userInfo: otherUserDetails.otherUser)
        case .group(let groupDetails):
            return groupDetails.displayName
        }
    }
    
    func chatNameFrom(userInfo: MessagingChatUserDisplayInfo) -> String {
        userInfo.displayName
    }
    
    func lastMessageTextFrom(message: MessagingChatMessageDisplayInfo) -> String  {
        switch message.type {
        case .text(let description):
            return description.text
        case .imageBase64:
            return String.Constants.photo.localized()
        }
    }
    
    func setNameText(_ text: String) {
        chatNameLabel.setAttributedTextWith(text: text,
                                            font: .currentFont(withSize: 16, weight: .medium),
                                            textColor: .foregroundDefault,
                                            lineBreakMode: .byTruncatingTail)
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
    
    func setAvatarFrom(url: URL?, name: String) {
        avatarImageView.clipsToBounds = true
        avatarImageView.image = .domainSharePlaceholder
        
        func setAvatarFromName() async {
            self.avatarImageView.image = await appContext.imageLoadingService.loadImage(from: .initials(name, size: .default, style: .accent),
                                                                                        downsampleDescription: nil)
        }
        
        Task {
            if let avatarURL = url {
                if let image = await appContext.imageLoadingService.loadImage(from: .url(avatarURL), downsampleDescription: nil) {
                    self.avatarImageView.image = image
                } else {
                    await setAvatarFromName()
                }
            } else {
                await setAvatarFromName()
            }
        }
    }
    
}
