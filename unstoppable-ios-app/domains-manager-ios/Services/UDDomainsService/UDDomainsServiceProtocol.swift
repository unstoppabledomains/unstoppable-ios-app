//
//  UDDomainsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import Foundation

protocol UDDomainsServiceProtocol {
    func getCachedDomainsFor(wallets: [UDWallet]) -> [DomainItem]
    func updateDomainsList(for userWallets:  [UDWallet]) async throws -> [DomainItem]
    func updatePFP(for domains: [DomainItem]) async throws -> [DomainItem]
    func getAllUnMintedDomains(for email: String,
                               securityCode: String) async throws -> [String]
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     to wallet: UDWallet,
                     userEmail: String,
                     securityCode: String) async throws -> [TransactionItem]
    
    func findDomains(by domainNames: [String]) -> [DomainItem]
    func getAllDomains() -> [DomainItem]
}
