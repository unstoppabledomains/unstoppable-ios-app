//
//  MessagingChatUserProfile.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.06.2023.
//

import Foundation

struct MessagingChatUserProfile: Hashable {
    let id: String
    let wallet: String
    var displayInfo: MessagingChatUserProfileDisplayInfo
    var serviceMetadata: Data?
}
