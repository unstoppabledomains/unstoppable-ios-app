//
//  MessagingPrivateChatBlockingStatus.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.07.2023.
//

import Foundation

enum MessagingPrivateChatBlockingStatus {
    case unblocked
    case currentUserIsBlocked
    case otherUserIsBlocked
    case bothBlocked
}
