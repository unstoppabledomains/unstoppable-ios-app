//
//  ChatUserBubbledMessageCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.07.2023.
//

import UIKit

class ChatUserBubbledMessageCell: ChatUserMessageCell {
    
    @IBOutlet private(set) weak var bubbleContainerView: UIView!

    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch sender {
        case .thisUser, .none:
            bubbleContainerView.layer.shadowPath = nil
        case .otherUser:
            bubbleContainerView.applyFigmaShadow(style: .xSmall)
        }
    }
    
    override func setWith(sender: MessagingChatSender) {
        super.setWith(sender: sender)
        
        setBubbleUI(bubbleContainerView, sender: sender)
    }
}
