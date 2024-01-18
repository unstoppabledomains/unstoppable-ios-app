//
//  WalletBalanceDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

typealias WalletBalance = WalletBalanceDisplayInfo

struct WalletBalanceDisplayInfo: Hashable, Codable {
    
    let address: String
    let exchangeRate: Double
    let blockchain: BlockchainType
    let coinBalance: Double
    let formattedCoinBalance: String
    let usdBalance: Double
    let formattedValue: String
    
    internal init(address: String, quantity: NetworkService.SplitQuantity, exchangeRate: Double, blockchain: BlockchainType) {
        self.address = address
        self.exchangeRate = exchangeRate
        self.blockchain = blockchain
        self.coinBalance = quantity.doubleEth
        self.usdBalance = coinBalance * exchangeRate
        self.formattedCoinBalance = currencyNumberFormatter.string(from: coinBalance as NSNumber) ?? "N/A"
        self.formattedValue = "\(formattedCoinBalance) \(blockchain.rawValue)"
    }
    
}
