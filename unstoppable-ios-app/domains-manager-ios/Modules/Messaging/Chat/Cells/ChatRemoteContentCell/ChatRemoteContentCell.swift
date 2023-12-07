//
//  ChatRemoteContentCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.07.2023.
//

import UIKit
import SwiftUI

final class ChatRemoteContentCell: ChatUserMessageCell {
    
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
}

// MARK: - Open methods
extension ChatRemoteContentCell {
    func setWith(configuration: ChatViewController.RemoteConfigMessageUIConfiguration) {
        (containerView as? UIStackView)?.alignment = configuration.message.senderType.isThisUser ? .trailing : .leading
        setWith(message: configuration.message, isGroupChatMessage: configuration.isGroupChatMessage)
        loadingIndicator.startAnimating()
    }
}

#Preview {
    let user = MockEntitiesFabric.Messaging.messagingChatUserDisplayInfo(withPFP: true)
    var typeDetails = MessagingChatMessageRemoteContentTypeDisplayInfo(serviceData: Data())
    
    let message = MessagingChatMessageDisplayInfo(id: "1",
                                                  chatId: "2",
                                                  userId: "1",
                                                  senderType: .otherUser(user),
                                                  time: Date(),
                                                  type: .remoteContent(typeDetails),
                                                  isRead: false,
                                                  isFirstInChat: true,
                                                  deliveryState: .delivered,
                                                  isEncrypted: false)
    let cell = ChatRemoteContentCell()
    cell.frame = CGRect(x: 0, y: 0, width: 390, height: 76)
    cell.setWith(configuration: .init(message: message,
                                      isGroupChatMessage: false,
                                      pressedCallback: { }))
    
    return cell
}
