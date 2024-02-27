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

// MARK: - Open methods
extension MessagingChatMessageDisplayType {
    func getContentDescriptionText() -> String  {
        switch self {
        case .text(let description):
            return description.text
        case .imageBase64, .imageData:
            return String.Constants.photo.localized()
        case .unknown:
            return String.Constants.messageNotSupported.localized()
        case .remoteContent:
            return String.Constants.messagingRemoteContent.localized()
        case .reaction(let info):
            return info.content
        case .reply(let info):
            return info.contentType.getContentDescriptionText()
        }
    }
}
