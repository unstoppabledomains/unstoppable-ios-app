//
//  WalletEntitiesStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation

final class WalletEntitiesStorage {
    
    private static let storageFileName = "wallets-entities.data"
    
    private init() {}
    static let instance = WalletEntitiesStorage()
    private var storage = SpecificStorage<[WalletEntity]>(fileName: WalletEntitiesStorage.storageFileName)
    
    func getCachedWallets() -> [WalletEntity] {
        storage.retrieve() ?? []
    }
    
    func cacheWallets(_ wallets: [WalletEntity]) {
        set(newWallets: wallets)
    }
    
    private func set(newWallets: [WalletEntity]) {
        storage.store(newWallets)
    }
}
