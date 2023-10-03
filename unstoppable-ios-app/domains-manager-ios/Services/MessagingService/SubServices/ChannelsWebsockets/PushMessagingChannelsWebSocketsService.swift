//
//  PushMessagingWebSocketsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation
import SocketIO
import Push

final class PushMessagingChannelsWebSocketsService: PushWebSocketsService, MessagingChannelsWebSocketsServiceProtocol {
    init() {
        super.init(connectionType: .channels)
    }
}
