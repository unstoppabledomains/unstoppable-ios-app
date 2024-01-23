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
    func getCachedDomainsPFPInfo() -> [DomainPFPInfo]
    func updateDomainsPFPInfo(for domains: [DomainItem]) async -> [DomainPFPInfo]
    func updateDomainsPFPInfo(for domainNames: [DomainName]) async -> [DomainPFPInfo]
    func loadPFP(for domainName: DomainName) async -> DomainPFPInfo?
    func getAllUnMintedDomains(for email: String,
                               securityCode: String) async throws -> [String]
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     to wallet: UDWallet,
                     userEmail: String,
                     securityCode: String) async throws 
    
    func findDomains(by domainNames: [String]) -> [DomainItem]
    func getAllDomains() -> [DomainItem]
    func getReferralCodeFor(domain: DomainItem) async throws -> String?
    
    // Resolution
    func resolveDomainOwnerFor(domainName: DomainName) async -> HexAddress?
}
