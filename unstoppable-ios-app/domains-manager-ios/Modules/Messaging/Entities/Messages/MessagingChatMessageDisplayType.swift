//
//  MessagingChatMessageDisplayType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

enum MessagingChatMessageDisplayType: Hashable {
    case text(MessagingChatMessageTextTypeDisplayInfo)
    case imageBase64(MessagingChatMessageImageBase64TypeDisplayInfo)
    // "File" | "GIF"
    
    var analyticName: String {
        switch self {
        case .text:
            return "text"
        case .imageBase64:
            return "image"
        }
    }
}
