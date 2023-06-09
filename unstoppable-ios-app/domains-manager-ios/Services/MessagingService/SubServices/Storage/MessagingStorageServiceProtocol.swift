//
//  MessagingStorageServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

protocol MessagingStorageServiceProtocol {
    func getMessages() async throws -> [MessagingChatMessage]
    func saveMessages(_ messages: [MessagingChatMessage]) async
    func getChatsFor(wallet: String) async throws -> [MessagingChat]
    func saveChats(_ chats: [MessagingChat]) async
}
