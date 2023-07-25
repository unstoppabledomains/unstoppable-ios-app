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
    case imageData(MessagingChatMessageImageDataTypeDisplayInfo)
    case unknown(MessagingChatMessageUnknownTypeDisplayInfo)
 
    var analyticName: String {
        switch self {
        case .text:
            return "Text"
        case .imageBase64, .imageData:
            return "Image"
        case .unknown(let info):
            return info.type
        }
    }
}
