//
//  MessagingServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

//MARK: - This is draft implementation to make UI done.
protocol MessagingServiceProtocol {
    func getChannelsForDomain(_ domain: DomainDisplayInfo,
                              page: Int,
                              limit: Int) async throws -> [ChatChannelType]
    func getNumberOfUnreadMessagesInChannelsForDomain(_ domain: DomainDisplayInfo) async throws -> Int
    func getMessagesForChannel(_ channel: ChatChannelType,
                               fetchLimit: Int) async throws -> [ChatMessageType]
}
