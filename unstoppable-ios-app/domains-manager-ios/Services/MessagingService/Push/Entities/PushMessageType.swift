//
//  PushMessageType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

enum PushMessageType: String, Codable {
    case text = "Text"
    case image = "Image"
    case video = "Video"
    case audio = "Audio"
    case file = "File"
    case gif = "GIF" // Deprecated, use mediaEmbed
    case mediaEmbed = "MediaEmbed"
    case meta = "Meta"
    case reply = "Reply"
    case reaction = "Reaction"
    case unknown
}
