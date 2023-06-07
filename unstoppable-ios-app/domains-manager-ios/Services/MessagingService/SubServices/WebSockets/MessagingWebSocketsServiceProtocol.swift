//
//  MessagingWebSocketsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingWebSocketsServiceProtocol {
    func subscribeFor(domain: DomainItem,
                      eventCallback: @escaping MessagingWebSocketEventCallback) throws
}

