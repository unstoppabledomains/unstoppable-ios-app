//
//  ChatBaseCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.06.2023.
//

import UIKit

class ChatBaseCell: UICollectionViewCell {
    
    @IBOutlet private(set) weak var containerView: UIView!

    private var containerViewSideConstraints: [NSLayoutConstraint] = []
    private(set) var sender: MessagingChatSender?
    var actionCallback: ((ChatViewController.ChatMessageAction)->())?

}

// MARK: - Open methods
extension ChatBaseCell {
    func setWith(message: MessagingChatMessageDisplayInfo) {
        guard sender != message.senderType else {
            return }
        
        self.removeConstraints(containerViewSideConstraints)
        let leadingConstraint: NSLayoutConstraint
        let trailingConstraint: NSLayoutConstraint
        if message.senderType.isThisUser {
            leadingConstraint = containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24)
            trailingConstraint = trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 8)
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        } else {
            leadingConstraint = containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
            trailingConstraint = trailingAnchor.constraint(greaterThanOrEqualTo: containerView.trailingAnchor, constant: 24)
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
        
        self.sender = message.senderType
        containerViewSideConstraints = [leadingConstraint, trailingConstraint]
        NSLayoutConstraint.activate(containerViewSideConstraints)
    }
}
