//
//  MessagingChatMessageDisplayType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

enum MessagingChatMessageDisplayType: Hashable {
    case text(MessagingChatMessageTextTypeDisplayInfo)
    // "Image" | "File" | "GIF"
}
