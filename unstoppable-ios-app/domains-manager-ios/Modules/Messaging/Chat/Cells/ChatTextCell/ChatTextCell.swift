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
    
    private var messageText = ""
    private var externalLinkHandleCallback: ChatMessageLinkPressedCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupTextView(messageTextView, externalLinkPressedCallback: { [weak self] url in
            self?.externalLinkHandleCallback?(url)
        })
    }
    
    override func getContextMenu() -> UIMenu? {
        if isGroupChatMessage,
           case .otherUser(let user) = sender {
            return  UIMenu(children: [
                UIAction(title: String.Constants.copy.localized(),
                         image: .copyToClipboardIcon) { [weak self] _ in
                    self?.actionCallback?(.copyText(self?.messageText ?? ""))
                },
                UIAction(title: String.Constants.blockUser.localized(),
                         image: .systemMultiplyCircle,
                         attributes: .destructive) { [weak self] _ in
                             self?.actionCallback?(.blockUserInGroup(user))
                }
            ])
        }
        return nil
    }
    
    override func getContextMenuPreviewFrame() -> CGRect? {
        var visibleFrame = convert(bubbleContainerView.frame, to: self)
        visibleFrame.size.height = frame.height
        let leadingOffsetToRemove: CGFloat = -25
        visibleFrame.size.width -= leadingOffsetToRemove
        visibleFrame.origin.x += leadingOffsetToRemove
        visibleFrame = visibleFrame.insetBy(dx: -15, dy: -10)
        return visibleFrame
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
        
        self.messageText = configuration.textMessageDisplayInfo.text
        messageTextView.setAttributedTextWith(text: messageText,
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
    let textDetails = MessagingChatMessageTextTypeDisplayInfo(text: "Som ")
    
    let message = MessagingChatMessageDisplayInfo(id: "1",
                                                  chatId: "2",
                                                  userId: "1",
                                                  senderType: .otherUser(user),
                                                  time: Date(),
                                                  type: .text(textDetails),
                                                  isRead: false,
                                                  isFirstInChat: true,
                                                  deliveryState: .delivered,
                                                  isEncrypted: true,
                                                  reactions: MockEntitiesFabric.Reactions.reactionsToTest)
    let collectionView = PreviewCollectionViewCell<ChatTextCell>(cellSize: CGSize(width: 390, height: 176)) { cell in
        cell.setWith(configuration: .init(message: message,
                                          textMessageDisplayInfo: textDetails,
                                          isGroupChatMessage: true,
                                          actionCallback: { _ in },
                                          externalLinkHandleCallback: { _ in }))
        cell.backgroundColor = .backgroundDefault
    }
    return collectionView
}
// MARK: - Private methods
extension ChatUserMessageCell {
   
    func calculateReactionsHeight() {
        guard let reactionsCollection,
            !reactionsCollection.isHidden else { return }
        
        let spacingsTotalWidth = CGFloat(reactions.count - 1) * 8
        let reactionsElementsWidth = reactions.reduce(CGFloat(0), { $0 + widthForReaction($1) })
        let reactionsTotalWidth = reactionsElementsWidth + spacingsTotalWidth
        let cellHeight: CGFloat = 38
        let collectionWidth = reactionsCollection.bounds.width
        
        let numberOfVerticalRows = ceil(reactionsTotalWidth / collectionWidth)
        let maxHeight: CGFloat = cellHeight * 2
        
        let requiredHeight = numberOfVerticalRows * cellHeight + (numberOfVerticalRows - 1) * 8
        let height = min(maxHeight, requiredHeight)
        if reactionsCollectionHeightConstraint?.constant != height {
            reactionsCollectionHeightConstraint?.constant = height
            invalidateIntrinsicContentSize()
        }
    }
    
    func widthForReaction(_ reaction: ReactionUIDescription) -> CGFloat {
        let counterWidth = String(reaction.count).width(withConstrainedHeight: 40,
                                                        font: ChatUserMessageReactionCell.counterFont)
        
        return counterWidth + 43
    }
    
}

