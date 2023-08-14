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

struct ChatRemoteContentCell_Previews: PreviewProvider {
    
    static var previews: some View {
        let height: CGFloat = 76
        
        return UICollectionViewCellPreview(cellType: ChatRemoteContentCell.self, height: height) { cell in
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
            cell.setWith(configuration: .init(message: message,
                                              isGroupChatMessage: false,
                                              pressedCallback: { }))
        }
        .frame(width: 390, height: 390)
    }
    
}
