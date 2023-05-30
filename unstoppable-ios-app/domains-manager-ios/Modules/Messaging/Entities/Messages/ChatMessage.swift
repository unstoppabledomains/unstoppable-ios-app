//
//  ChatMessage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

class ChatMessage: Hashable {
    
    let id: String
    let sender: ChatSender
    let time: Date
    let avatarURL: URL?
    
    init(id: String, sender: ChatSender, time: Date, avatarURL: URL? = nil) {
        self.id = id
        self.sender = sender
        self.time = time
        self.avatarURL = avatarURL
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
