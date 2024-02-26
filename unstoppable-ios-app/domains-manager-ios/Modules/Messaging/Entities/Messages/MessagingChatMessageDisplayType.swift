//
//  MessagingChatMessageDisplayType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

indirect enum MessagingChatMessageDisplayType: Hashable {
    case text(MessagingChatMessageTextTypeDisplayInfo)
    case imageBase64(MessagingChatMessageImageBase64TypeDisplayInfo)
    case imageData(MessagingChatMessageImageDataTypeDisplayInfo)
    case unknown(MessagingChatMessageUnknownTypeDisplayInfo)
    case remoteContent(MessagingChatMessageRemoteContentTypeDisplayInfo)
    case reaction(MessagingChatMessageReactionTypeDisplayInfo)
    case reply(MessagingChatMessageReplyTypeDisplayInfo)
 
    var analyticName: String {
        switch self {
        case .text:
            return "Text"
        case .imageBase64, .imageData:
            return "Image"
        case .unknown(let info):
            return info.type
        case .remoteContent:
            return "RemoteContent"
        case .reaction:
            return "Reaction"
        case .reply:
            return "Reply"
        }
    }
}
