//
//  WalletTransactionsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

final class WalletTransactionsService {

    private let networkService: WalletTransactionsNetworkServiceProtocol
    
    init(networkService: WalletTransactionsNetworkServiceProtocol) {
        self.networkService = networkService
    }

}

// MARK: - WalletTransactionsServiceProtocol
extension WalletTransactionsService: WalletTransactionsServiceProtocol {
    func getTransactionsFor(wallet: HexAddress, 
                            cursor: String?,
                            chain: String?) async throws -> [TransactionsPerChainResponse] {
        try await networkService.getTransactionsFor(wallet: wallet,
                                                    cursor: cursor,
                                                    chain: chain)
    }
}
