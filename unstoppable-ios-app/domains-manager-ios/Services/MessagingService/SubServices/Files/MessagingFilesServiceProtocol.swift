//
//  MessagingFilesServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.07.2023.
//

import Foundation

protocol MessagingFilesServiceProtocol {
    /// Encrypted
    func getEncryptedDataURLFor(fileName: String) -> URL?
    @discardableResult
    func saveEncryptedData(_ data: Data, fileName: String) throws -> URL
    func deleteEncryptedDataWith(fileName: String)
    
    /// Decrypted
    func getDecryptedDataURLFor(fileName: String) -> URL?
    @discardableResult
    func saveDecryptedData(_ data: Data, fileName: String) throws -> URL
}
