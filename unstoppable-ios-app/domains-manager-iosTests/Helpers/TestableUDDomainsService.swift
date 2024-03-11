//
//  TestableUDDomainsService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import Foundation
@testable import domains_manager_ios

final class TestableUDDomainsService: UDDomainsServiceProtocol {
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
    
    func updateDomainsPFPInfo(for domainNames: [DomainName]) async -> [DomainPFPInfo] {
        []
    }
    
    func loadPFP(for domainName: DomainName) async -> DomainPFPInfo? {
        nil
    }
    
    func getAllUnMintedDomains(for email: String, securityCode: String) async throws -> [String] {
        []
    }
    
    func mintDomains(_ domains: [String], paidDomains: [String], to wallet: UDWallet, userEmail: String, securityCode: String) async throws {
        
    }
    
    func findDomains(by domainNames: [String]) -> [DomainItem] {
        []
    }
    
    func getAllDomains() -> [DomainItem] {
        [
    }
    
    func getReferralCodeFor(domain: DomainItem) async throws -> String? {
        nil
    }
    
    func resolveDomainOwnerFor(domainName: DomainName) async -> HexAddress? {
        nil
    }
    
    
}
