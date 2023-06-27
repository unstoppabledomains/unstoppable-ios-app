//
//  ChatTextCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

final class ChatTextCell: ChatUserMessageCell {

    @IBOutlet private weak var bubbleContainerView: UIView!
    @IBOutlet private weak var messageTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupTextView(messageTextView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch sender {
        case .thisUser, .none:
            bubbleContainerView.layer.shadowPath = nil
        case .otherUser:
            bubbleContainerView.applyFigmaShadow(style: .xSmall)
        }
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
        
        setWith(message: textMessage)
        setBubbleUI(bubbleContainerView, sender: textMessage.senderType)
    }
}
