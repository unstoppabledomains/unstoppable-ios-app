//
//  PushPublicKeysStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.07.2023.
//

import Foundation

final class PushPublicKeysStorage {
    
    typealias Entity = PushEnvironment.ChatPublicKeysHolder
    private static let pushPublicKeysStorageFileName = "push-public-keys.data"
    
    static var instance = PushPublicKeysStorage()
    private var storage = SpecificStorage<[Entity]>(fileName: PushPublicKeysStorage.pushPublicKeysStorageFileName)

    private init() {}
    
    func getKeysHolders() -> [Entity] {
        storage.retrieve() ?? []
    }
    
    func getCachedKeys(for chatId: String) -> Entity? {
        let holders = getKeysHolders()
        
        return holders.first(where: { $0.chatId == chatId })
    }
    
    func saveKeysHoldersInfo(_ pfpInfoArray: [Entity]) {
        var holdersCache = getKeysHolders()
        for pfpInfo in pfpInfoArray {
            if let i = holdersCache.firstIndex(where: { $0.chatId == pfpInfo.chatId }) {
                holdersCache[i] = pfpInfo
            } else {
                holdersCache.append(pfpInfo)
            }
        }
        set(newHolders: holdersCache)
    }
    
    private func set(newHolders: [Entity]) {
        storage.store(newHolders)
    }
}
