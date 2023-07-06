//
//  ChatUnsupportedMessageCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.07.2023.
//

import UIKit

final class ChatUnsupportedMessageCell: ChatUserBubbledMessageCell {

    @IBOutlet private weak var messageTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupTextView(messageTextView)
        messageTextView.text = String.Constants.notSupported.localized()
    }

}

// MARK: - Open methods
extension ChatUnsupportedMessageCell {
    func setWith(configuration: ChatViewController.UnsupportedMessageUIConfiguration) {
        
        setWith(message: configuration.message)
    }
}
