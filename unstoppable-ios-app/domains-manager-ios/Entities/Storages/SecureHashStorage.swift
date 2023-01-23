//
//  SecureHashStorage.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 19.01.2023.
//

import Foundation

struct SecureHashStorage {
    enum Key: String {
        case currentStoragePasswordHash = "CURRENT_PASSWORD_HASH"
    }
    
    enum Error: Swift.Error {
        case failedToHash
        case currentPasswordNotSet
    }
    
    static func save(password: String) throws {
        guard let backUpPassword = WalletBackUpPassword(password) else {
            throw Error.failedToHash
        }
        save(string: backUpPassword.value, key: .currentStoragePasswordHash)
    }
    
    static private func save(string: String, key: Key) {
        UserDefaults.standard.set(string, forKey: key.rawValue)
    }
    
    static func retrievePassword() -> String? {
        retrieve(key: .currentStoragePasswordHash)
    }
        
    static private func retrieve(key: Key) -> String? {
        UserDefaults.standard.object(forKey: key.rawValue) as? String
    }
    
    static func clearPassword() {
        clean(key: .currentStoragePasswordHash)
    }
    
    static private func clean(key: Key)  {
        UserDefaults.standard.set(nil, forKey: key.rawValue)
    }
}
