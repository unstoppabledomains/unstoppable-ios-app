//
//  MessagingChatUserProfileDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.06.2023.
//

import Foundation

struct MessagingChatUserProfileDisplayInfo: Hashable {
    let id: String
    let wallet: String
    let serviceIdentifier: String
    var name: String?
    var about: String?
    var unreadMessagesCount: Int?
}
