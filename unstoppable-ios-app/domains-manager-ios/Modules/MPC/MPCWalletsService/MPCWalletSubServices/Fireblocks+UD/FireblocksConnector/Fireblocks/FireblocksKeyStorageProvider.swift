//
//  FireblocksKeyStorageProvider.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.03.2024.
//

import Foundation
import FireblocksSDK
import Valet

final class FireblocksKeyStorageProvider {
    private let storage: ValetProtocol = FB_UD_MPC.ValetStorage()
}

// MARK: - Open methods
extension FireblocksKeyStorageProvider: KeyStorageDelegate {
    func store(keys: [String : Data], callback: @escaping ([String : Bool]) -> ()) {
        logMPC("Keychain: Will store keys: \(keys.keys)")
        var result: [String : Bool] = [:]
        for (key, data) in keys {
            do {
                try storage.setObject(data, forKey: key)
                result[key] = true
            } catch {
                result[key] = false
            }
        }
        
        callback(result)
    }
    
    func remove(keyId: String) {
        logMPC("Keychain: Will Remove key with id \(keyId)")
        
        try? storage.removeObject(forKey: keyId)
    }
    
    func load(keyIds: Set<String>, callback: @escaping ([String : Data]) -> ()) {
        logMPC("Keychain: Will load keys with id \(keyIds)")
        
        var result: [String : Data] = [:]
        
        for key in keyIds {
            if let data = try? storage.object(forKey: key) {
                result[key] = data
            } else {
                logMPC("Keychain: Failed to find requested MPC Key")
            }
        }
        
        callback(result)
    }
    
    func contains(keyIds: Set<String>, callback: @escaping ([String : Bool]) -> ())  {
        logMPC("Keychain: Will check if contains keys with id \(keyIds)")
        
        var result: [String : Bool] = [:]
        for key in keyIds {
            if (try? storage.object(forKey: key)) != nil {
                result[key] = true
            } else {
                logMPC("Keychain: Not containing MPC Key")
            }
        }
        
        callback(result)
    }
}

extension FireblocksKeyStorageProvider {
    
}
