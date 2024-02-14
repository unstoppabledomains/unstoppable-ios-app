//
//  ChatUnsupportedMessageCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.07.2023.
//

import UIKit
import SwiftUI

final class ChatUnsupportedMessageCell: ChatUserBubbledMessageCell {

    @IBOutlet private weak var iconContainerView: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!
    @IBOutlet private weak var downloadButton: UDConfigurableButton!
        
    override var isFlexibleWidth: Bool { false }
    private var pressedCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        iconContainerView.layer.cornerRadius = 8
        iconContainerView.layer.borderWidth = 1
        iconContainerView.layer.borderColor = UIColor.borderMuted.cgColor
        downloadButton.isUserInteractionEnabled = false
        downloadButton.titleLeftPadding = 0
        downloadButton.setConfiguration(.smallGhostPrimaryButtonConfiguration)
        let downloadTitle = String.Constants.download.localized()
        downloadButton.setTitle(downloadTitle, image: nil)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }
    
}

// MARK: - Open methods
extension ChatUnsupportedMessageCell {
    func setWith(configuration: ChatViewController.UnsupportedMessageUIConfiguration) {
        let message = configuration.message
        guard case .unknown(let details) = message.type else { return }
        
        pressedCallback = configuration.pressedCallback
        let messageColor: UIColor
        let secondaryLabelColor: UIColor
        let primaryLabelText: String
        let icon: UIImage
        
        if let name = details.name {
            primaryLabelText = name
            icon = .docsIcon24
        } else {
            primaryLabelText = String.Constants.messageNotSupported.localized()
            icon = .helpIcon24
        }
  
        switch message.senderType {
        case .thisUser:
            messageColor = .white
            secondaryLabelColor = .foregroundOnEmphasisOpacity
            iconContainerView.backgroundColor = .backgroundMuted2
            downloadButton.setConfiguration(.smallGhostPrimaryWhiteButtonConfiguration)
        case .otherUser:
            messageColor = .foregroundDefault
            secondaryLabelColor = .foregroundSecondary
            iconContainerView.backgroundColor = .backgroundMuted2
            downloadButton.setConfiguration(.smallGhostPrimaryButtonConfiguration)
        }
        iconImageView.tintColor = messageColor
        primaryLabel.setAttributedTextWith(text: primaryLabelText,
                                           font: .currentFont(withSize: 16, weight: .regular),
                                           textColor: messageColor,
                                           lineBreakMode: .byTruncatingMiddle)
        iconImageView.image = icon
        
        
        if let size = details.size {
            secondaryLabel.isHidden = false
            downloadButton.isHidden = false
            let formattedSize = bytesFormatter.string(fromByteCount: Int64(size))
            let secondaryText = "(\(formattedSize))"
            secondaryLabel.setAttributedTextWith(text: secondaryText,
                                                 font: .currentFont(withSize: 14, weight: .regular),
                                                 textColor: secondaryLabelColor)
        } else {
            secondaryLabel.isHidden = true
            downloadButton.isHidden = true
        }
        
        
        setWith(message: message, isGroupChatMessage: configuration.isGroupChatMessage)
    }
    
    @objc func didTap() {
        UDVibration.buttonTap.vibrate()
        pressedCallback?()
    }
}

@available (iOS 17.0, *)
#Preview {
    let user = MockEntitiesFabric.Messaging.messagingChatUserDisplayInfo(withPFP: true)
    let unknownMessageInfo = MessagingChatMessageUnknownTypeDisplayInfo(fileName: "",
                                                                        type: "file",
                                                                        name: "sjlhfksdjfhskdj",
                                                                        size: 99900)
    let message = MessagingChatMessageDisplayInfo(id: "1",
                                                  chatId: "2",
                                                  userId: "1",
                                                  senderType: .otherUser(user),
                                                  time: Date(),
                                                  type: .unknown(unknownMessageInfo),
                                                  isRead: false,
                                                  isFirstInChat: true,
                                                  deliveryState: .delivered,
                                                  isEncrypted: false,
                                                  reactions: MockEntitiesFabric.Reactions.reactionsToTest)
    let collectionView = PreviewCollectionViewCell<ChatUnsupportedMessageCell>(cellSize: CGSize(width: 390, height: 126)) { cell in
        cell.setWith(configuration: .init(message: message,
                                          isGroupChatMessage: false,
                                          pressedCallback: { }))
        cell.backgroundColor = .backgroundDefault
    }
    return collectionView
    
}
