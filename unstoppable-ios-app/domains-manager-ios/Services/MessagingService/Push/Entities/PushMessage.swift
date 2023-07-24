//
//  PushMessage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation

struct PushMessage: Hashable, Codable {
    let fromCAIP10: String
    let toCAIP10: String
    let fromDID: String
    let toDID: String
    let messageType: PushMessageType
    let messageContent: String
    let signature: String
    let sigType: String
    let timestamp: Int?
    let encType: String
    let encryptedSecret: String
    let verificationProof: String
    let link: String?
    
    // When message created
    let cid: String?
    let chatId: String?
}
