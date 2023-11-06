//
//  PushMessagingWebSocketsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

final class PushMessagingChannelsWebSocketsService: PushWebSocketsService, MessagingChannelsWebSocketsServiceProtocol {
    init() {
        super.init(connectionType: .channels)
    }
}
