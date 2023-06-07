//
//  ChatTextCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

final class ChatTextCell: UICollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var messageTextView: UITextView!
    @IBOutlet private weak var timeLabel: UILabel!
    
    private var textViewSideConstraints: [NSLayoutConstraint] = []
    private var sender: MessagingChatSender?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        messageTextView.dataDetectorTypes = [.link]
        messageTextView.backgroundColor = .clear
        messageTextView.textContainerInset = .zero
        messageTextView.showsVerticalScrollIndicator = false
        messageTextView.showsHorizontalScrollIndicator = false
        
        containerView.layer.cornerRadius = 12
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch sender {
        case .thisUser, .none:
            containerView.layer.shadowPath = nil
        case .otherUser:
            containerView.applyFigmaShadow(style: .xSmall)
        }
    }

}

// MARK: - Open methods
extension ChatTextCell {
    func setWith(configuration: ChatViewController.TextMessageUIConfiguration) {
        let textMessage = configuration.message
        let messageColor: UIColor = textMessage.senderType.isThisUser ? .white : .foregroundDefault
        
        messageTextView.setAttributedTextWith(text: configuration.textMessageDisplayInfo.text,
                                              font: .currentFont(withSize: 16, weight: .regular),
                                              textColor: messageColor,
                                              lineHeight: 24)
        
        let timeColor: UIColor = textMessage.senderType.isThisUser ? .foregroundOnEmphasisOpacity : .foregroundSecondary
        let formatterTime = MessageDateFormatter.formatMessageDate(textMessage.time)
        timeLabel.setAttributedTextWith(text: formatterTime,
                                        font: .currentFont(withSize: 12, weight: .regular),
                                        textColor: timeColor,
                                        lineHeight: 16)
        
        guard sender != textMessage.senderType else {
            return }
        
        self.removeConstraints(textViewSideConstraints)
        let leadingConstraint: NSLayoutConstraint
        let trailingConstraint: NSLayoutConstraint
        if textMessage.senderType.isThisUser {
            leadingConstraint = containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24)
            trailingConstraint = trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 8)
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        } else {
            leadingConstraint = containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
            trailingConstraint = trailingAnchor.constraint(greaterThanOrEqualTo: containerView.trailingAnchor, constant: 24)
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
        setBubbleUI(sender: textMessage.senderType)
        
        self.sender = textMessage.senderType
        textViewSideConstraints = [leadingConstraint, trailingConstraint]
        NSLayoutConstraint.activate(textViewSideConstraints)
    }
}

// MARK: - Private methods
private extension ChatTextCell {
    func setBubbleUI(sender: MessagingChatSender?) {
        if sender?.isThisUser == true {
            containerView.backgroundColor = .backgroundAccentEmphasis
        } else {
            containerView.backgroundColor = .backgroundOverlay
        }
    }
}
