//
//  WalletsDataNetworkServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.03.2024.
//

import Foundation

protocol WalletsDataNetworkServiceProtocol {
    func fetchCryptoPortfolioFor(wallet: String) async throws -> [WalletTokenPortfolio]
    func fetchProfileRecordsFor(domainName: String) async throws -> [String : String]
}
