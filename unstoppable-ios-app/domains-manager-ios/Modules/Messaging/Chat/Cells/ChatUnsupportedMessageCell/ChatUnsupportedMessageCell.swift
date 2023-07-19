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
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var downloadButton: UDButton!
    
    private var otherUserAvatarView: UIImageView?
    
    override var isFlexibleWidth: Bool { false }
    private var pressedCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        iconContainerView.layer.cornerRadius = 8
        iconContainerView.layer.borderWidth = 1
        iconContainerView.layer.borderColor = UIColor.borderMuted.cgColor
        downloadButton.isUserInteractionEnabled = false
        downloadButton.setConfiguration(.smallGhostPrimaryButtonConfiguration)
        let downloadTitle = String.Constants.download.localized()
        downloadButton.setTitle(downloadTitle, image: nil)
        downloadButton.widthAnchor.constraint(equalToConstant: downloadTitle.width(withConstrainedHeight: .greatestFiniteMagnitude,
                                                                                   font: downloadButton.font)).isActive = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }
    
}

// MARK: - Open methods
extension ChatUnsupportedMessageCell {
    func setWith(configuration: ChatViewController.UnsupportedMessageUIConfiguration) {
        let textMessage = configuration.message
        guard case .unknown(let details) = textMessage.type else { return }
        
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
  
        setupOtherUserAvatarViewIf(isGroupChatMessage: configuration.isGroupChatMessage, senderType: textMessage.senderType)
        switch textMessage.senderType {
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
        
        
        setWith(message: textMessage)
        print(downloadButton.frame)
    }
    
    @objc func didTap() {
        UDVibration.buttonTap.vibrate()
        pressedCallback?()
    }
    
    func setupOtherUserAvatarViewIf(isGroupChatMessage: Bool, senderType: MessagingChatSender) {
        switch senderType {
        case .thisUser:
            setupOtherUserAvatarView(nil)
        case .otherUser(let userInfo):
            if isGroupChatMessage {
                setupOtherUserAvatarView(userInfo)
            } else {
                setupOtherUserAvatarView(nil)
            }
        }
    }
    
    func setupOtherUserAvatarView(_ userInfo: MessagingChatUserDisplayInfo?) {
        if let userInfo {
            if otherUserAvatarView == nil {
                let otherUserAvatarView = UIImageView()
                self.otherUserAvatarView = otherUserAvatarView
                otherUserAvatarView.translatesAutoresizingMaskIntoConstraints = false
                contentStackView.spacing = 8
                contentStackView.alignment = .center
                let size: CGFloat = 36
                otherUserAvatarView.heightAnchor.constraint(equalToConstant: size).isActive = true
                otherUserAvatarView.widthAnchor.constraint(equalTo: otherUserAvatarView.heightAnchor, multiplier: 1).isActive = true
                otherUserAvatarView.clipsToBounds = true
                otherUserAvatarView.layer.cornerRadius = size / 2
            }
            contentStackView.insertArrangedSubview(otherUserAvatarView!, at: 0)
            loadAvatarForOtherUserInfo(userInfo)
        } else {
            otherUserAvatarView?.removeFromSuperview()
        }
    }
    
    func loadAvatarForOtherUserInfo(_ userInfo: MessagingChatUserDisplayInfo) {
        Task {
            let name = userInfo.domainName ?? userInfo.wallet.droppedHexPrefix
            otherUserAvatarView?.image = await appContext.imageLoadingService.loadImage(from: .initials(name,
                                                                                                        size: .default,
                                                                                                        style: .accent),
                                                                                        downsampleDescription: nil)
            if let pfpURL = userInfo.pfpURL,
               let pfp = await appContext.imageLoadingService.loadImage(from: .url(pfpURL),
                                                                          downsampleDescription: nil) {
                otherUserAvatarView?.image = pfp
            }
        }
    }
}

struct ChatUnsupportedMessageCell_Previews: PreviewProvider {
    
    static var previews: some View {
        let height: CGFloat = 76
        
        return UICollectionViewCellPreview(cellType: ChatUnsupportedMessageCell.self, height: height) { cell in
            let user = MockEntitiesFabric.Messaging.messagingChatUserDisplayInfo(withPFP: true)
            let unknownMessageInfo = MessagingChatMessageUnknownTypeDisplayInfo(fileName: "",
                                                                                type: "file",
                                                                                name: "sjlhfksdjfhskdjhfskdhjfksdjfhsdfsdf",
                                                                                size: 99900)
            let message = MessagingChatMessageDisplayInfo(id: "1",
                                                          chatId: "2",
                                                          senderType: .otherUser(user),
                                                          time: Date(),
                                                          type: .unknown(unknownMessageInfo),
                                                          isRead: false,
                                                          isFirstInChat: true,
                                                          deliveryState: .delivered,
                                                          isEncrypted: false)
            cell.setWith(configuration: .init(message: message,
                                              isGroupChatMessage: false,
                                              pressedCallback: { }))
        }
        .frame(width: 390, height: height)
    }
    
}
