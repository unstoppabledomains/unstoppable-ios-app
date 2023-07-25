//
//  MessagingFilesService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.07.2023.
//

import Foundation

final class MessagingFilesService {
    
    private let fileManager = FileManager.default
    private let decrypterService: MessagingContentDecrypterService

    init(decrypterService: MessagingContentDecrypterService) {
        self.decrypterService = decrypterService
        checkDirectoriesExists()
    }
    
}

// MARK: - MessagingFilesServiceProtocol
extension MessagingFilesService: MessagingFilesServiceProtocol {
    ///
    @discardableResult
    func saveData(_ data: Data, fileName: String) throws -> URL {
        let base64 = data.base64EncodedString()
        let encryptedBase64 = try decrypterService.encryptText(base64)
        let encryptedData = try stringToBase64Data(encryptedBase64)
        return try saveEncryptedData(encryptedData, fileName: fileName)
    }
    
    func deleteDataWith(fileName: String) {
        let url = urlToFileWith(fileName: fileName, dataType: .encrypted)
        try? fileManager.removeItem(at: url)
        if let decryptedURL = getDecryptedDataURLFor(fileName: fileName) {
            try? fileManager.removeItem(at: decryptedURL)
        }
    }
    
    func decryptedContentURLFor(message: MessagingChatMessageDisplayInfo) async -> URL? {
        let fileName: String
        
        switch message.type {
        case .text, .imageBase64, .imageData:
            return nil
        case .unknown(let info):
            fileName = info.fileName
        }
        
        if let url = getDecryptedDataURLFor(fileName: fileName) {
            return url
        }
        
        guard let encryptedDataURL = getEncryptedDataURLFor(fileName: fileName),
              let encryptedData = try? Data(contentsOf: encryptedDataURL),
              let decryptedContent = try? decrypterService.decryptText(encryptedData.base64EncodedString()),
              let decryptedData = Base64DataTransformer.dataFrom(base64String: decryptedContent) else { return nil }
        
        return try? saveDecryptedData(decryptedData, fileName: fileName)
    }
}

// MARK: - Open methods
extension MessagingFilesService {
    func clear() {
        func clearAllFor(dataType: MessagingDataType) {
            let folderURL = folderURLFor(dataType: dataType)
            let fileURLs = (try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)) ?? []
            for fileURL in fileURLs {
                try? fileManager.removeItem(at: fileURL)
            }
        }
        
        clearAllFor(dataType: .encrypted)
        clearAllFor(dataType: .decrypted)
    }
}

// MARK: - Private methods
private extension MessagingFilesService {
    func stringToBase64Data(_ string: String) throws -> Data {
        guard let data = Data(base64Encoded: string) else { throw MessagingFilesError.failedToCreateBase64Data }
    
        return data
    }
    
    func getEncryptedDataURLFor(fileName: String) -> URL? {
        getURLIfFileExistFor(fileName: fileName, dataType: .encrypted)
    }
    
    @discardableResult
    func saveEncryptedData(_ data: Data, fileName: String) throws -> URL {
        try saveData(data, fileName: fileName, dataType: .encrypted)
    }
    
    func getDecryptedDataURLFor(fileName: String) -> URL? {
        getURLIfFileExistFor(fileName: fileName, dataType: .decrypted)
    }
    
    @discardableResult
    func saveDecryptedData(_ data: Data, fileName: String) throws -> URL {
        try saveData(data, fileName: fileName, dataType: .decrypted)
    }
    
    func getURLIfFileExistFor(fileName: String, dataType: MessagingDataType) -> URL? {
        let url = urlToFileWith(fileName: fileName, dataType: dataType)
        if fileManager.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }
    
    func saveData(_ data: Data, fileName: String, dataType: MessagingDataType) throws -> URL {
        let url = urlToFileWith(fileName: fileName, dataType: dataType)
        
        // Check if file already saved
        if let existingData = try? Data(contentsOf: url) {
            if existingData == data {
                return url
            } else {
                try fileManager.removeItem(at: url)
            }
        }
        
        try data.write(to: url)
        return url
    }
    
    func urlToFileWith(fileName: String, dataType: MessagingDataType) -> URL {
        let folderURL = folderURLFor(dataType: dataType)
        return folderURL.appendingPathComponent(fileName)
    }
    
    func folderURLFor(dataType: MessagingDataType) -> URL {
        switch dataType {
        case .encrypted:
            let directoryPath = directoryPath(for: .chats)
            return URL(fileURLWithPath: directoryPath as String)
        case .decrypted:
            return fileManager.temporaryDirectory
        }
    }
    
    func checkDirectoriesExists() {
        for directory in Directory.allCases {
            let directoryPath = directoryPath(for: directory)
            if !fileManager.fileExists(atPath: directoryPath) {
                do {
                    try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    Debugger.printFailure("Error: Couldn't create directory \(directory.rawValue)", critical: true)
                }
            }
        }
    }
    
    func directoryPath(for directory: Directory) -> String {
        (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(directory.rawValue)
    }
}

// MARK: - Private methods
private extension MessagingFilesService {
    enum MessagingFilesError: String, LocalizedError {
        case failedToCreateBase64Data
        
        public var errorDescription: String? { rawValue }

    }
    
    enum MessagingDataType {
        case encrypted
        case decrypted
    }
    
    enum Directory: String,  CaseIterable {
        case chats
    }
}
