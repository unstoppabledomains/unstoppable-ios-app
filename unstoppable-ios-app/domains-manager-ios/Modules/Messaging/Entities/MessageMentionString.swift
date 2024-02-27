//
//  MessageMentionString.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.02.2024.
//

import Foundation

struct MessageMentionString {
    
    static let messageMentionPrefix = "@"
    
    let mentionWithPrefix: String
    let mentionWithoutPrefix: String
    
    init?(string: String) {
        guard string.first == MessageMentionString.messageMentionPrefix.first else { return nil }
        
        self.mentionWithPrefix = string
        self.mentionWithoutPrefix = String(string.dropFirst())
    }
    
    static func makeMentionFrom(string: String) -> MessageMentionString? {
        if let mention = MessageMentionString(string: string) { // Check if already mention first
            return mention
        }
        
        let mentionString = messageMentionPrefix + string
        return MessageMentionString(string: mentionString)
    }
    
}
