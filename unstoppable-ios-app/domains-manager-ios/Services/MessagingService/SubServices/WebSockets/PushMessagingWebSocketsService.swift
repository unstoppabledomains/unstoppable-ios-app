//
//  PushMessagingWebSocketsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.10.2023.
//

import Foundation

final class PushMessagingWebSocketsService: PushWebSocketsService, MessagingWebSocketsServiceProtocol {
    init() {
        super.init(connectionType: .chats)
    }
}
