//
//  PreviewWalletPortfolioRecordsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.02.2024.
//

import Foundation

final class WalletPortfolioRecordsStorage {
    
    static let instance = WalletPortfolioRecordsStorage()
    private init() { }
    
    private var cache: [String : [WalletPortfolioRecord]] = [:]
    
    func getRecords(for wallet: String) -> [WalletPortfolioRecord] {
        cache[wallet, default: []].sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    func saveRecords(_ records: [WalletPortfolioRecord], for wallet: String) {
        cache[wallet] = records
    }
    
}
