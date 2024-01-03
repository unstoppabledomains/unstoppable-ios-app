//
//  ChatTextCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit
import SwiftUI

final class ChatTextCell: ChatUserBubbledMessageCell {

    @IBOutlet private weak var messageTextView: UITextView!
    
    private var externalLinkHandleCallback: ChatMessageLinkPressedCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupTextView(messageTextView, externalLinkPressedCallback: { [weak self] url in
            self?.externalLinkHandleCallback?(url)
        })
    }
    

}

// MARK: - Open methods
extension ChatTextCell {
    func setWith(configuration: ChatViewController.TextMessageUIConfiguration) {
        self.actionCallback = configuration.actionCallback
        self.externalLinkHandleCallback = configuration.externalLinkHandleCallback
        let textMessage = configuration.message
        var messageColor: UIColor = textMessage.senderType.isThisUser ? .white : .foregroundDefault
        
        if case .failedToSend = textMessage.deliveryState {
            messageColor = .foregroundOnEmphasisOpacity
        }
        
        messageTextView.setAttributedTextWith(text: configuration.textMessageDisplayInfo.text,
                                              font: .currentFont(withSize: 16, weight: .regular),
                                              textColor: messageColor,
                                              lineHeight: 24)
        messageTextView.linkTextAttributes = [.foregroundColor: messageColor,
                                              .underlineStyle: NSUnderlineStyle.single.rawValue]
        
        setWith(message: textMessage, isGroupChatMessage: configuration.isGroupChatMessage)
    }
}

@available (iOS 17.0, *)
#Preview {
    let user = MockEntitiesFabric.Messaging.messagingChatUserDisplayInfo(withPFP: true)
    let textDetails = MessagingChatMessageTextTypeDisplayInfo(text: "Some text message")
    
    let message = MessagingChatMessageDisplayInfo(id: "1",
                                                  chatId: "2",
                                                  userId: "1",
                                                  senderType: .thisUser(user),
                                                  time: Date(),
                                                  type: .text(textDetails),
                                                  isRead: false,
                                                  isFirstInChat: true,
                                                  deliveryState: .failedToSend,
                                                  isEncrypted: false)
    
    let collection = UICollectionView(frame: .zero, collectionViewLayout: .init())
    collection.registerCellNibOfType(ChatTextCell.self)
    
    let cell = collection.dequeueCellOfType(ChatTextCell.self, forIndexPath: IndexPath(row: 0, section: 0))
    
    cell.frame = CGRect(x: 0, y: 0, width: 390, height: 76)
    cell.alpha = 1
    cell.setWith(configuration: .init(message: message,
                                      textMessageDisplayInfo: textDetails,
                                      isGroupChatMessage: true,
                                      actionCallback: { _ in },
                                      externalLinkHandleCallback: { _ in }))
    
    return cell
}
