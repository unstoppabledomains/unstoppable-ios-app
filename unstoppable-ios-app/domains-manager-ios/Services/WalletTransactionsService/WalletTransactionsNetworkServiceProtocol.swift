//
//  WalletTransactionsNetworkServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

protocol WalletTransactionsNetworkServiceProtocol {
    func getTransactionsFor(wallet: HexAddress, cursor: String?, chain: String?) async throws -> [TransactionsPerChainResponse]
}
