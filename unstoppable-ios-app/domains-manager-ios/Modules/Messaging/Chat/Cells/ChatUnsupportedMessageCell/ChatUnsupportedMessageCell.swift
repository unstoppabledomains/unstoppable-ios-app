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
    @IBOutlet private weak var downloadButton: UDButton!
    
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
        let primaryLabelText: String
        let icon: UIImage
        
        if let name = details.name {
            primaryLabelText = name
            icon = .docsIcon24
        } else {
            primaryLabelText = String.Constants.messageNotSupported.localized()
            icon = .helpIcon24
        }
        
        if let size = details.size {
            secondaryLabel.isHidden = false
            downloadButton.isHidden = false
            let formattedSize = bytesFormatter.string(fromByteCount: Int64(size))
            let secondaryText = "(\(formattedSize))"
            secondaryLabel.setAttributedTextWith(text: secondaryText,
                                                 font: .currentFont(withSize: 14, weight: .regular),
                                                 textColor: .foregroundSecondary)
        } else {
            secondaryLabel.isHidden = true
            downloadButton.isHidden = true
        }
        
        switch textMessage.senderType {
        case .thisUser:
            messageColor = .white
            iconContainerView.backgroundColor = .backgroundMuted2
        case .otherUser:
            messageColor = .foregroundDefault
            iconContainerView.backgroundColor = .backgroundMuted2
            iconImageView.tintColor = .black
        }
        primaryLabel.setAttributedTextWith(text: primaryLabelText,
                                           font: .currentFont(withSize: 16, weight: .regular),
                                           textColor: messageColor,
                                           lineBreakMode: .byTruncatingMiddle)
        iconImageView.image = icon
        
        setWith(message: textMessage)
        print(downloadButton.frame)
    }
    
    @objc func didTap() {
        UDVibration.buttonTap.vibrate()
        pressedCallback?()
    }
}

struct ChatUnsupportedMessageCell_Previews: PreviewProvider {
    
    static var previews: some View {
        let height: CGFloat = 76
        
        return UICollectionViewCellPreview(cellType: ChatUnsupportedMessageCell.self, height: height) { cell in
            let user = MessagingChatUserDisplayInfo(wallet: "24")
            let unknownMessageInfo = MessagingChatMessageUnknownTypeDisplayInfo(fileName: "",
                                                                                type: "file",
                                                                                name: "Filenaskjdskjdfhsdkfjhskdfjhsdkfjhhfsde.pdf",
                                                                                size: 99900)
            let message = MessagingChatMessageDisplayInfo(id: "1",
                                                          chatId: "2",
                                                          senderType: .otherUser(user),
                                                          time: Date(),
                                                          type: .unknown(unknownMessageInfo),
                                                          isRead: true,
                                                          isFirstInChat: true,
                                                          deliveryState: .delivered)
            cell.setWith(configuration: .init(message: message, pressedCallback: { }))
        }
        .frame(width: 390, height: height)
    }
    
}
