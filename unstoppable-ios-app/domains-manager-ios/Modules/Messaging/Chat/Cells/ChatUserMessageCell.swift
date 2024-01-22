//
//  ChatUserMessageCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.06.2023.
//

import UIKit

class ChatUserMessageCell: ChatBaseCell {
    
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var timeStackView: UIStackView!
    @IBOutlet private weak var deleteButton: FABRaisedTertiaryButton?
    @IBOutlet private weak var contentHStackView: UIStackView!

    private var otherUserAvatarView: UIImageView?
    private var otherUserInfo: MessagingChatUserDisplayInfo?
    private var timeLabelTapGesture: UITapGestureRecognizer?
    private var timeLabelAction: ChatViewController.ChatMessageAction = .resend
    private(set) var isGroupChatMessage = false
    var actionCallback: ((ChatViewController.ChatMessageAction)->())?

    override func awakeFromNib() {
        super.awakeFromNib()
                
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        let timeLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapTimeLabel))
        timeLabel.addGestureRecognizer(timeLabelTapGesture)
        self.timeLabelTapGesture = timeLabelTapGesture
        deleteButton?.setTitle(nil, image: .trashIcon16)
        deleteButton?.tintColor = .foregroundDefault
    }
    
    override func setWith(sender: MessagingChatSender) {
        super.setWith(sender: sender)
        
        if sender.isThisUser {
            timeStackView.alignment = .trailing
        } else {
            timeStackView.alignment = .leading
        }
    }
 
    func setWith(message: MessagingChatMessageDisplayInfo,
                 isGroupChatMessage: Bool) {
        self.isGroupChatMessage = isGroupChatMessage
        switch message.deliveryState {
        case .delivered:
            timeLabelTapGesture?.isEnabled = false
            deleteButton?.isHidden = true
            let formatterTime = MessageDateFormatter.formatMessageDate(message.time)
            if message.isEncrypted {
                timeLabel.setAttributedTextWith(text: formatterTime,
                                                font: .currentFont(withSize: 11, weight: .regular),
                                                textColor: .foregroundSecondary)
            } else {
                let unencryptedWord = String.Constants.unencrypted.localized()
                let text: String
                switch message.senderType {
                case .thisUser:
                    text = "\(unencryptedWord) · \(formatterTime)"
                case .otherUser:
                    text = "\(formatterTime) · \(unencryptedWord)"
                }
                timeLabel.setAttributedTextWith(text: text,
                                                font: .currentFont(withSize: 11, weight: .regular),
                                                textColor: .foregroundSecondary)
                timeLabel.updateAttributesOf(text: unencryptedWord,
                                             textColor: .foregroundAccent)
                timeLabelTapGesture?.isEnabled = true
                timeLabelAction = .unencrypted
            }
        case .sending:
            timeLabelTapGesture?.isEnabled = false
            deleteButton?.isHidden = true
            timeLabel.setAttributedTextWith(text: String.Constants.sending.localized() + "...",
                                            font: .currentFont(withSize: 11, weight: .regular),
                                            textColor: .foregroundSecondary)
        case .failedToSend:
            timeLabelTapGesture?.isEnabled = true
            timeLabelAction = .resend
            deleteButton?.isHidden = false
            let fullText = String.Constants.sendingFailed.localized() + ". " + String.Constants.tapToRetry.localized()
            timeLabel.setAttributedTextWith(text: fullText,
                                            font: .currentFont(withSize: 11, weight: .semibold),
                                            textColor: .foregroundDanger)
            timeLabel.updateAttributesOf(text: String.Constants.tapToRetry.localized(),
                                         textColor: .foregroundAccent)
        }
        timeLabel.isUserInteractionEnabled = timeLabelTapGesture?.isEnabled == true
        setWith(sender: message.senderType)
        setupOtherUserAvatarViewIf(isGroupChatMessage: isGroupChatMessage,
                                   senderType: message.senderType)
    }
    
 
}

// MARK: - Other user avatar
extension ChatUserMessageCell {
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
                otherUserAvatarView.isUserInteractionEnabled = true
                otherUserAvatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSelectOtherUserProfile)))
                self.otherUserAvatarView = otherUserAvatarView
                otherUserAvatarView.translatesAutoresizingMaskIntoConstraints = false
                contentHStackView.spacing = 8
                contentHStackView.alignment = .center
                let size: CGFloat = 36
                otherUserAvatarView.heightAnchor.constraint(equalToConstant: size).isActive = true
                otherUserAvatarView.widthAnchor.constraint(equalTo: otherUserAvatarView.heightAnchor, multiplier: 1).isActive = true
                otherUserAvatarView.clipsToBounds = true
                otherUserAvatarView.layer.cornerRadius = size / 2
            }
            contentHStackView.insertArrangedSubview(otherUserAvatarView!, at: 0)
            loadAvatarForOtherUserInfo(userInfo)
        } else {
            otherUserAvatarView?.removeFromSuperview()
        }
    }
    
    func loadAvatarForOtherUserInfo(_ userInfo: MessagingChatUserDisplayInfo) {
        otherUserInfo = userInfo
        Task {
            let name = userInfo.domainName ?? userInfo.wallet.droppedHexPrefix
            otherUserAvatarView?.image = await appContext.imageLoadingService.loadImage(from: .initials(name,
                                                                                                        size: .default,
                                                                                                        style: .accent),
                                                                                        downsampleDescription: nil)
            
            let image = await appContext.imageLoadingService.loadImage(from: .messagingUserPFPOrInitials(userInfo,
                                                                                                         size: .default),
                                                                       downsampleDescription: .icon)
            if userInfo.wallet == self.otherUserInfo?.wallet {
                otherUserAvatarView?.image = image
            }
        }
    }
}

// MARK: - Private methods
private extension ChatUserMessageCell {
    @objc func didTapTimeLabel() {
        UDVibration.buttonTap.vibrate()
        actionCallback?(timeLabelAction)
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        actionCallback?(.delete)
    }
    
    @objc func didSelectOtherUserProfile() {
        guard let sender else { return }
        
        actionCallback?(.viewSenderProfile(sender))
    }
}
