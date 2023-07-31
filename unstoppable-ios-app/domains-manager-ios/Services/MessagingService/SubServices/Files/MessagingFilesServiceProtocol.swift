//
//  MessagingFilesServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.07.2023.
//

import Foundation

protocol MessagingFilesServiceProtocol {
    init(decrypterService: MessagingContentDecrypterService)

    @discardableResult
    func saveData(_ data: Data, fileName: String) throws -> URL
    func deleteDataWith(fileName: String)
    func decryptedContentURLFor(message: MessagingChatMessageDisplayInfo) async -> URL?
}
