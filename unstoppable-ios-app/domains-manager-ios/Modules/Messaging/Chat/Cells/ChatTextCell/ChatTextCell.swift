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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupTextView(messageTextView)
    }
    

}

// MARK: - Open methods
extension ChatTextCell {
    func setWith(configuration: ChatViewController.TextMessageUIConfiguration) {
        self.actionCallback = configuration.actionCallback
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

struct ChatTextCell_Previews: PreviewProvider {
    
    static var previews: some View {
        let height: CGFloat = 76
        
        return UICollectionViewCellPreview(cellType: ChatTextCell.self, height: height) { cell in
            let user = MockEntitiesFabric.Messaging.messagingChatUserDisplayInfo(withPFP: true)
            let textDetails = MessagingChatMessageTextTypeDisplayInfo(text: "Some text message", encryptedText: "")
            
            let message = MessagingChatMessageDisplayInfo(id: "1",
                                                          chatId: "2",
                                                          userId: "1",
                                                          senderType: .thisUser(user),
                                                          time: Date(),
                                                          type: .text(textDetails),
                                                          isRead: false,
                                                          isFirstInChat: true,
                                                          deliveryState: .delivered,
                                                          isEncrypted: false)
            cell.setWith(configuration: .init(message: message,
                                              textMessageDisplayInfo: textDetails,
                                              isGroupChatMessage: true,
                                              actionCallback: { _ in }))
        }
        .frame(width: 390, height: height)
    }
    
}
