//
//  WCConnectionIntentStorage.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 07.07.2022.
//

import Foundation

class WCConnectionIntentStorage: DefaultsStorage<WCConnectionIntentStorage.Intent> {

    static let shared = WCConnectionIntentStorage()
    override private init() {
        super.init()
        storageKey = "SERVER_CONNECTION_INTENTS_STORAGE"
        q = DispatchQueue(label: "work-queue-connecttion-intents")
    }
    
    func retrieveIntents() -> [Intent] {
        super.retrieveAll()
    }
    
    func save(newIntent: Intent) {
        super.save(newElement: newIntent)
    }

    func getIntent(by accounts: [HexAddress]) -> Intent? {
        let normalizedAccounts = accounts.map({$0.normalized})
        return retrieveIntents().first(where: { normalizedAccounts
            .contains($0.walletAddress.normalized) } )
    }
    
    func replaceIntent(with newIntent: Intent, foundBy accounts: [HexAddress]) async -> Intent? {
        let normalizedAccounts = accounts.map({ $0.normalized })
        return await replace(with: newIntent) {
            normalizedAccounts.contains($0.walletAddress.normalized)
        }
    }
    
    func replaceIntent(address: HexAddress,
                       foundBy accounts: [HexAddress]) async -> Intent? {
        let newIntent = Intent(walletAddress: address,
                               requiredNamespaces: nil,
                               appData: nil)
        return await replaceIntent(with: newIntent, foundBy: accounts)
    }
}
