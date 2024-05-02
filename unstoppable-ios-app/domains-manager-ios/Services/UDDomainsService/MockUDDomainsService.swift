//
//  MockUDDomainsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import Foundation
import UIKit

#if DEBUG
final class MockUDDomainsService {
    
    private let DomainsLimit = 200
    private var domains = [DomainItem]()
    private let mockImageNames = [""]
    private var primaryDomainName: String?
    private let shouldMockPrimaryDomain = false
    private let shouldShakePrimaryDomain = false
    private let workingQueue = DispatchQueue(label: "mock.domains")
    private var walletToDomains: [String : [DomainItem]] = [:]
    
}

// MARK: - UDDomainsServiceProtocol
extension MockUDDomainsService: UDDomainsServiceProtocol {

    func findDomains(by domainNames: [String]) -> [DomainItem] {
        []
    }
    
    func getCachedDomainsFor(wallets: [UDWallet]) -> [DomainItem] {
        var domains = [DomainItem]()
        for wallet in wallets {
            domains += walletToDomains[wallet.address] ?? []
        }
        return domains
    }
    
    func updateDomainsList(for wallet: UDWallet) async throws -> [DomainItem] {
        workingQueue.sync {
            if domains.isEmpty {
                    for _ in 0..<TestsEnvironment.numberOfDomainsToUse {
                        if let domain = addDomain(suffix: "_",
                                                  wallet: wallet.address) {
                            walletToDomains[wallet.address, default: []].append(domain)
                        }
                    }
            }
            return domains
        }
    }

    func loadPFP(for domainName: DomainName) async -> DomainPFPInfo? { nil }
    
    func getCachedDomainsPFPInfo() -> [DomainPFPInfo] {
        []
    }
    
    func updateDomainsPFPInfo(for domains: [DomainItem]) async -> [DomainPFPInfo] {
        []
    }
    func updateDomainsPFPInfo(for domainNames: [DomainName]) async -> [DomainPFPInfo] { [] }

    func getAllUnMintedDomains(for email: String, securityCode: String) async throws -> [String] {
        await Task.sleep(seconds: 0.3)
        
//        var domains = ["coolguy.coin"]
//
//        for i in 0..<60 {
//            let tld = i > 5 ? "crypto" : "coin"
//            domains.append("domain_\(i).\(tld)")
//        }
//        return domains
        
//        return []
//        return ["coolguy.coin"]
        return ["coolguy.crypto"]
//        return ["coolguy.crypto",  "coolguy.coin"]
//        return ["coolguy.crypto", "evencoolerguy.x", "abc.x", "daniil.nft", "jongordon.x", "one.x", "two.x", "three.crypto", "four.x", "five.x", "six.x", "seven.x", "eight.x"]
    }
    
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     to wallet: UDWallet,
                     userEmail: String,
                     securityCode: String) async throws { }
    
    func resolveDomainOwnerFor(domainName: DomainName) async -> HexAddress? { nil }
}

// MARK: - Open test functions
extension MockUDDomainsService {
    func setDomainsWith(names: [String], to wallet: HexAddress) {
        for name in names {
            if let i = domains.firstIndex(where: { $0.name == name }) {
                domains[i].ownerWallet = wallet
            }
        }
    }
}

// MARK: - Private methods
private extension MockUDDomainsService {
    
    @discardableResult
    func addDomain(suffix: String = "",
                   blockchain: BlockchainType = .Matic,
                   isMinting: Bool = false,
                   wallet: String? = nil) -> DomainItem? {
        if self.domains.count < self.DomainsLimit {
            let tld = "x"
            var newDomain = DomainItem(name: "coolguy_\(self.domains.count)_\(suffix).\(tld)")
            newDomain.blockchain = blockchain
            if let wallet {
                newDomain.ownerWallet = wallet
            }
            
            Debugger.printInfo(topic: .Domain, "Will add domain \(newDomain.name)")

            self.domains.append(newDomain)
            return newDomain
        }
        return nil
    }
}
#endif
