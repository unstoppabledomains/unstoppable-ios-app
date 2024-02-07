//
//  WalletPortfolioRecordsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.02.2024.
//

import Foundation

struct WalletPortfolioRecordsStorage {
    private static let storageFileName = "wallets-portfolio-records.data"
    
    private init() {}
    static var instance = WalletPortfolioRecordsStorage()
    private var storage = SpecificStorage<[WalletPortfolioRecord]>(fileName: WalletPortfolioRecordsStorage.storageFileName)
    
    private func getAllRecords() -> [WalletPortfolioRecord] {
        storage.retrieve() ?? []
    }
    
    func getRecords(for wallet: String) -> [WalletPortfolioRecord] {
        getAllRecords().filter { $0.wallet == wallet }.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    func saveRecords(_ records: [WalletPortfolioRecord], for wallet: String) {
        var currentRecords = getAllRecords().filter({ $0.wallet == wallet })
        currentRecords.append(contentsOf: records)
        setRecords(currentRecords)
    }
    
    private func setRecords(_ newRecords: [WalletPortfolioRecord]) {
        storage.store(newRecords)
    }
    
}
