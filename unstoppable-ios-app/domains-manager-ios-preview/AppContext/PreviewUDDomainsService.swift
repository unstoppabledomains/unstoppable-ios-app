//
//  PreviewDomainTransactions.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

final class UDDomainsService: UDDomainsServiceProtocol {
    func getCachedDomainsFor(wallets: [UDWallet]) -> [DomainItem] {
        []
    }
    
    func updateDomainsList(for userWallets: [UDWallet]) async throws -> [DomainItem] {
        []
    }
    
    func getCachedDomainsPFPInfo() -> [DomainPFPInfo] {
        []
    }
    
    func updateDomainsPFPInfo(for domains: [DomainItem]) async -> [DomainPFPInfo] {
        []
    }
    
    func loadPFP(for domainName: DomainName) async -> DomainPFPInfo? {
        nil
    }
    
    func getAllUnMintedDomains(for email: String, securityCode: String) async throws -> [String] {
        []
    }
    
    func mintDomains(_ domains: [String], paidDomains: [String], to wallet: UDWallet, userEmail: String, securityCode: String) async throws -> [TransactionItem] {
        []
    }
    
    func findDomains(by domainNames: [String]) -> [DomainItem] {
        []
    }
    
    func getAllDomains() -> [DomainItem] {
        []
    }
    
    func getReferralCodeFor(domain: DomainItem) async throws -> String? {
        nil
    }
    
    func resolveDomainOwnerFor(domainName: DomainName) async -> HexAddress? {
        nil
    }
    
    
}
