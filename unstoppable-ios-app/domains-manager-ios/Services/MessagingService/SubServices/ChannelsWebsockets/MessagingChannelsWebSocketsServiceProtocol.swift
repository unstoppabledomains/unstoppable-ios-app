//
//  MessagingChannelsWebSocketsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.08.2023.
//

import Foundation

protocol MessagingChannelsWebSocketsServiceProtocol {
    func subscribeFor(profile: MessagingChatUserProfile,
                      eventCallback: @escaping MessagingWebSocketEventCallback) throws
    func disconnectAll()
}
