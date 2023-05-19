//
//  ChatTextMessage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

final class ChatTextMessage: ChatMessage {
    
    let text: String
    
    internal init(id: UUID = .init(), sender: DomainName, time: Date, avatarURL: URL? = nil, text: String) {
        self.text = text
        super.init(id: id, sender: sender, time: time, avatarURL: avatarURL)
    }
    
}
