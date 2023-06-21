//
//  ChatTextCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

final class ChatTextCell: ChatBaseCell {

    @IBOutlet private weak var bubbleContainerView: UIView!
    @IBOutlet private weak var messageTextView: UITextView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var timeStackView: UIStackView!
    @IBOutlet private weak var deleteButton: FABRaisedTertiaryButton!
    
    private var timeLabelTapGesture: UITapGestureRecognizer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupTextView(messageTextView)
        
        let timeLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapTimeLabel))
        timeLabel.addGestureRecognizer(timeLabelTapGesture)
        self.timeLabelTapGesture = timeLabelTapGesture
        deleteButton.setTitle(nil, image: .trashIcon16)
        deleteButton.tintColor = .foregroundDefault
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
        
        switch configuration.message.deliveryState {
        case .delivered:
            timeLabelTapGesture?.isEnabled = false
            deleteButton.isHidden = true
            let formatterTime = MessageDateFormatter.formatMessageDate(textMessage.time)
            timeLabel.setAttributedTextWith(text: formatterTime,
                                            font: .currentFont(withSize: 11, weight: .regular),
                                            textColor: .foregroundSecondary)
        case .sending:
            timeLabelTapGesture?.isEnabled = false
            deleteButton.isHidden = true
            timeLabel.setAttributedTextWith(text: String.Constants.sending.localized() + "...",
                                            font: .currentFont(withSize: 11, weight: .regular),
                                            textColor: .foregroundSecondary)
        case .failedToSend:
            messageColor = .foregroundOnEmphasisOpacity
            timeLabelTapGesture?.isEnabled = true
            deleteButton.isHidden = false
            let fullText = String.Constants.sendingFailed.localized() + ". " + String.Constants.tapToRetry.localized()
            timeLabel.setAttributedTextWith(text: fullText,
                                            font: .currentFont(withSize: 11, weight: .semibold),
                                            textColor: .foregroundDanger)
            timeLabel.updateAttributesOf(text: String.Constants.tapToRetry.localized(),
                                         textColor: .foregroundAccent)
        }
        timeLabel.isUserInteractionEnabled = timeLabelTapGesture?.isEnabled == true
        
        messageTextView.setAttributedTextWith(text: configuration.textMessageDisplayInfo.text,
                                              font: .currentFont(withSize: 16, weight: .regular),
                                              textColor: messageColor,
                                              lineHeight: 24)
        messageTextView.linkTextAttributes = [.foregroundColor: messageColor,
                                              .underlineStyle: NSUnderlineStyle.single.rawValue]
        
        setWith(sender: configuration.message.senderType)
        
        if textMessage.senderType.isThisUser {
            timeStackView.alignment = .trailing
        } else {
            timeStackView.alignment = .leading
        }
        
        setBubbleUI(bubbleContainerView, sender: textMessage.senderType)
    }
}

// MARK: - Private methods
private extension ChatTextCell {
    @objc func didTapTimeLabel() {
        UDVibration.buttonTap.vibrate()
        actionCallback?(.resend)
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        actionCallback?(.delete)
    }
}
