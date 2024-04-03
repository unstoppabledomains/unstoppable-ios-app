//
//  WalletBalancesStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.03.2024.
//

import Foundation

final class WalletBalancesStorage {
    
    private static let storageFileName = "wallets-balances-entities.data"
    
    private init() {}
    static let instance = WalletBalancesStorage()
    private var storage = SpecificStorage<[StoredWalletBalances]>(fileName: WalletBalancesStorage.storageFileName)
    
    func getCachedBalancesFor(domainName: DomainName) -> [WalletTokenPortfolio] {
        (storage.retrieve() ?? []).first(where: { $0.domainName == domainName })?.balances ?? []
    }
    
    func cacheBalances(_ balances: [WalletTokenPortfolio], for domainName: DomainName) {
        var storedBalances = storage.retrieve() ?? []
        let newBalance = StoredWalletBalances(domainName: domainName, balances: balances)
        if let i = storedBalances.firstIndex(where: { $0.domainName == domainName }) {
            storedBalances[i] = newBalance
        } else {
            storedBalances.append(newBalance)
        }
        
        set(newBalances: storedBalances)
    }
    
    private func set(newBalances: [StoredWalletBalances]) {
        storage.store(newBalances)
    }
}

// MARK: - Private methods
private extension WalletBalancesStorage {
    struct StoredWalletBalances: Codable {
        let domainName: String
        let balances: [WalletTokenPortfolio]
    }
}
