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
    func setWith(configuration: ChatsListViewController.ChatChannelUIConfiguration) {
        let channelType = configuration.channelType
        avatarImageView.image = .domainSharePlaceholder
        if let avatarURL = channelType.avatarURL {
            Task {
                let image = await appContext.imageLoadingService.loadImage(from: .url(avatarURL), downsampleDescription: nil)
                self.avatarImageView.image = image
            }
        }
        
        let chatName = chatNameFrom(channelType: channelType)
        chatNameLabel.setAttributedTextWith(text: chatName,
                                            font: .currentFont(withSize: 16, weight: .medium),
                                            textColor: .foregroundDefault)
        
        if let lastMessage = channelType.lastMessage {
            let time = MessageDateFormatter.formatChannelDate(lastMessage.time)
            timeLabel.setAttributedTextWith(text: time,
                                            font: .currentFont(withSize: 13, weight: .regular),
                                            textColor: .foregroundSecondary)
            
            let lastMessageText = lastMessageTextFrom(messageType: lastMessage)
            lastMessageLabel.setAttributedTextWith(text: lastMessageText,
                                                   font: .currentFont(withSize: 14, weight: .regular),
                                                   textColor: .foregroundSecondary,
                                                   lineHeight: 20,
                                                   lineBreakMode: .byTruncatingTail)
        } else {
            timeLabel.text = ""
            lastMessageLabel.text = ""
        }
        
        badgeView.setUnreadMessagesCount(channelType.unreadMessagesCount)
    }
}


// MARK: - Private methods
private extension ChatListCell {
    func chatNameFrom(channelType: ChatChannelType) -> String {
        switch channelType {
        case .domain(let channel):
            return channel.domainName
        }
    }
    
    func lastMessageTextFrom(messageType: ChatMessageType) -> String  {
        switch messageType {
        case .text(let message):
            return message.text
        }
    }
}
