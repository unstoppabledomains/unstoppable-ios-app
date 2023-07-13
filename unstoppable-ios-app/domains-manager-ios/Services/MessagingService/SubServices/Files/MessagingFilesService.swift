//
//  MessagingFilesService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.07.2023.
//

import Foundation

final class MessagingFilesService {
    
    private let fileManager = FileManager.default

    init() {
        checkDirectoriesExists()
    }
    
}

// MARK: - Open methods
extension MessagingFilesService: MessagingFilesServiceProtocol {
    /// Encrypted
    func getEncryptedDataURLFor(id: String) -> URL? {
        getURLIfFileExistFor(id: id, dataType: .encrypted)
    }
    
    @discardableResult
    func saveEncryptedData(_ data: Data, id: String) throws -> URL {
        try saveData(data, id: id, dataType: .encrypted)
    }
    
    func deleteEncryptedDataWith(id: String) {
        let url = urlToFileWith(id: id, dataType: .encrypted)
        try? fileManager.removeItem(at: url)
    }
    
    /// Decrypted
    func getDecryptedDataURLFor(id: String) -> URL? {
        getURLIfFileExistFor(id: id, dataType: .decrypted)
    }
    
    @discardableResult
    func saveDecryptedData(_ data: Data, id: String) throws -> URL {
        try saveData(data, id: id, dataType: .decrypted)
    }
}

// MARK: - Private methods
private extension MessagingFilesService {
    func getURLIfFileExistFor(id: String, dataType: MessagingDataType) -> URL? {
        let url = urlToFileWith(id: id, dataType: dataType)
        if fileManager.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }
    
    func saveData(_ data: Data, id: String, dataType: MessagingDataType) throws -> URL {
        let url = urlToFileWith(id: id, dataType: dataType)
        
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
    
    func urlToFileWith(id: String, dataType: MessagingDataType) -> URL {
        let folderURL = folderURLFor(dataType: dataType)
        return folderURL.appendingPathComponent(id)
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
    enum MessagingDataType {
        case encrypted
        case decrypted
    }
    
    enum Directory: String,  CaseIterable {
        case chats
    }
}
