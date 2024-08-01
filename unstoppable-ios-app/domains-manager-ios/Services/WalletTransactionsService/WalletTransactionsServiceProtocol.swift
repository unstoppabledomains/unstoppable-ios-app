//
//  WalletTransactionsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

protocol WalletTransactionsServiceProtocol {
    func getTransactionsFor(wallet: HexAddress,
                            chains: [BlockchainType]?,
                            forceReload: Bool) async throws -> WalletTransactionsResponse
}
