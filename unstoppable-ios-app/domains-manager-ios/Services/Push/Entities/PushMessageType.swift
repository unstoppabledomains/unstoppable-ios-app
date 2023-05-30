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
    case file = "File"
    case gif = "GIF"
    }
