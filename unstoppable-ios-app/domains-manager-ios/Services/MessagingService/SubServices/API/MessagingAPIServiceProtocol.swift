//
//  MessagingAPIServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingAPIServiceProtocol {
    func getChannels(for domain: DomainDisplayInfo,
                     page: Int,
                     limit: Int) async throws -> [ChatChannelType]
    func getMessagesForChannel(_ channel: ChatChannelType,
                               fetchLimit: Int) async throws -> [ChatMessageType]
}


