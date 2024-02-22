//
//  PushPublicKeysStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.07.2023.
//

import Foundation

final class PushChatsSecretKeysStorage {
    
    typealias Entity = PushEnvironment.SessionKeyWithSecret
    
    private static let pushPublicKeysStorageFileName = "push-chats-secret-keys.data"
    
    static var instance = PushChatsSecretKeysStorage()
    private var storage = SpecificStorage<[Entity]>(fileName: PushChatsSecretKeysStorage.pushPublicKeysStorageFileName)
    private var decryptedSessionKeyToSecretKeyCache: [String : String] = [:]
    private let decrypterService = AESMessagingContentDecrypterService()
    private let queue = DispatchQueue(label: "com.push.chats.secret")

    private init() {
        let keys = getKeysHolders()
        for key in keys {
            let decryptedKey = try? decrypterService.decryptText(key.secretKey)
            decryptedSessionKeyToSecretKeyCache[key.sessionKey] = decryptedKey
        }
    }
    
    private func getKeysHolders() -> [Entity] {
        storage.retrieve() ?? []
    }
    
    func getSecretKeyFor(sessionKey: String) -> String? {
        queue.sync {
            decryptedSessionKeyToSecretKeyCache[sessionKey]
        }
    }
    
    func saveNew(keys: PushEnvironment.SessionKeyWithSecret) throws {
        guard decryptedSessionKeyToSecretKeyCache[keys.sessionKey] == nil else { return }
        
        let encryptedSecretKey = try decrypterService.encryptText(keys.secretKey)
        queue.sync {
            decryptedSessionKeyToSecretKeyCache[keys.sessionKey] = keys.secretKey
        }
        let encryptedKeys = PushEnvironment.SessionKeyWithSecret(sessionKey: keys.sessionKey, secretKey: encryptedSecretKey)
        
        var holdersCache = getKeysHolders()
        holdersCache.append(encryptedKeys)
        set(newKeys: holdersCache)
    }
    
    private func set(newKeys: [Entity]) {
        storage.store(newKeys)
    }
}
