//
//  ChatBaseCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.06.2023.
//

import UIKit

typealias ChatMessageLinkPressedCallback = @Sendable @MainActor (URL)->()

class ChatBaseCell: UICollectionViewCell {
    
    @IBOutlet private(set) weak var containerView: UIView!

    var isFlexibleWidth: Bool { true }
    
    private var containerViewSideConstraints: [NSLayoutConstraint] = []
    private(set) var sender: MessagingChatSender?
    private var externalLinkPressedCallback: ChatMessageLinkPressedCallback?

    func setWith(sender: MessagingChatSender) {
        guard self.sender != sender else {
            return }
        
        self.removeConstraints(containerViewSideConstraints)
        let leadingConstraint: NSLayoutConstraint
        let trailingConstraint: NSLayoutConstraint
        if sender.isThisUser {
            if isFlexibleWidth {
                leadingConstraint = containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24)
            } else {
                leadingConstraint = containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24)
            }
            trailingConstraint = trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 8)
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        } else {
            leadingConstraint = containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
            if isFlexibleWidth {
                trailingConstraint = trailingAnchor.constraint(greaterThanOrEqualTo: containerView.trailingAnchor, constant: 24)
            } else {
                trailingConstraint = trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 24)
            }
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
        
        self.sender = sender
        containerViewSideConstraints = [leadingConstraint, trailingConstraint]
        NSLayoutConstraint.activate(containerViewSideConstraints)
    }
}

// MARK: - Open methods
extension ChatBaseCell {
    func setupTextView(_ textView: UITextView, externalLinkPressedCallback: ChatMessageLinkPressedCallback?) {
        self.externalLinkPressedCallback = externalLinkPressedCallback
        textView.dataDetectorTypes = [.link]
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainerInset.top = -4
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
    }
    
    func setBubbleUI(_ bubbleView: UIView,
                     sender: MessagingChatSender?) {
        bubbleView.layer.cornerRadius = 12
        if sender?.isThisUser == true {
            bubbleView.backgroundColor = .backgroundAccentEmphasis
        } else {
            bubbleView.backgroundColor = .backgroundMuted2
        }
    }
}

// MARK: - Open methods
extension ChatBaseCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard let externalLinkPressedCallback else { return true }
        UDVibration.buttonTap.vibrate()
        
        externalLinkPressedCallback(URL)
        return false
    }
}
