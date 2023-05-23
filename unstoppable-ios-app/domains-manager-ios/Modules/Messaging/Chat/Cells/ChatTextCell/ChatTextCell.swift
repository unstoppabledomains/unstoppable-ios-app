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
    private var sender: ChatSender?

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
        case .user, .none:
            containerView.layer.shadowPath = nil
        case .friend:
            containerView.applyFigmaShadow(style: .xSmall)
        }
    }

}

// MARK: - Open methods
extension ChatTextCell {
    func setWith(configuration: ChatViewController.TextMessageUIConfiguration) {
        let textMessage = configuration.message
        let messageColor: UIColor = textMessage.sender == .user ? .white : .foregroundDefault
        
        messageTextView.setAttributedTextWith(text: textMessage.text,
                                              font: .currentFont(withSize: 16, weight: .regular),
                                              textColor: messageColor,
                                              lineHeight: 24)
        
        let timeColor: UIColor = textMessage.sender == .user ? .foregroundOnEmphasisOpacity : .foregroundSecondary
        let formatterTime = MessageDateFormatter.formatMessageDate(textMessage.time)
        timeLabel.setAttributedTextWith(text: formatterTime,
                                        font: .currentFont(withSize: 12, weight: .regular),
                                        textColor: timeColor,
                                        lineHeight: 16)
        
        guard sender != textMessage.sender else {
            return }
        
        self.removeConstraints(textViewSideConstraints)
        let leadingConstraint: NSLayoutConstraint
        let trailingConstraint: NSLayoutConstraint
        if textMessage.sender == .user {
            leadingConstraint = containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24)
            trailingConstraint = trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 8)
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        } else {
            leadingConstraint = containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
            trailingConstraint = trailingAnchor.constraint(greaterThanOrEqualTo: containerView.trailingAnchor, constant: 24)
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
        setBubbleUI(sender: textMessage.sender)
        
        self.sender = textMessage.sender
        textViewSideConstraints = [leadingConstraint, trailingConstraint]
        NSLayoutConstraint.activate(textViewSideConstraints)
    }
}

// MARK: - Private methods
private extension ChatTextCell {
    func setBubbleUI(sender: ChatSender?) {
        if sender == .user {
            containerView.backgroundColor = .backgroundAccentEmphasis
        } else {
            containerView.backgroundColor = .backgroundOverlay
        }
    }
}
