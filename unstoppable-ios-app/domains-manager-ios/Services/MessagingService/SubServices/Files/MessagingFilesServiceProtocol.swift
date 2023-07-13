//
//  MessagingFilesServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.07.2023.
//

import Foundation

protocol MessagingFilesServiceProtocol {
    /// Encrypted
    func getEncryptedDataURLFor(id: String) -> URL?
    @discardableResult
    func saveEncryptedData(_ data: Data, id: String) throws -> URL
    func deleteEncryptedDataWith(id: String)
    
    /// Decrypted
    func getDecryptedDataURLFor(id: String) -> URL?
    @discardableResult
    func saveDecryptedData(_ data: Data, id: String) throws -> URL
}
