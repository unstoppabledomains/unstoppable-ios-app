//
//  UDDomainsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import Foundation

final class UDDomainsService {
        
    private let storage: Storage = Storage.instance
    private let domainsPFPStorage = DomainsPFPInfoStorage.instance
    
}

// MARK: - UDDomainsServiceProtocol
extension UDDomainsService: UDDomainsServiceProtocol {
    func getCachedDomainsFor(wallets: [UDWallet]) -> [DomainItem] {
        let domains = storage.getCachedDomainsArray_Blocking(for: wallets)
        return domains
    }
    
    func findDomains(by domainNames: [String]) -> [DomainItem] {
        storage.findDomains(by: domainNames)
    }
    
    func getAllDomains() -> [DomainItem] { storage.getAllDomains() }
  
    func updateDomainsList(for wallets:  [UDWallet]) async throws -> [DomainItem] {
        guard !wallets.isEmpty else { return [] }
        
        async let fetchUNSDomainsTask = NetworkService().fetchUnsDomains(for: wallets)
        async let fetchZILDomainsTask = NetworkService().fetchZilDomains(for: wallets)

        let start = Date()
        let (unsDomainArray, zilDomainsArray) = try await (fetchUNSDomainsTask, fetchZILDomainsTask)
        let combinedDomains = unsDomainArray + zilDomainsArray
        Debugger.printTimeSensitiveInfo(topic: .Domain,
                                        "to load \((combinedDomains).count) domains for \(wallets.count) wallets",
                                        startDate: start,
                                        timeout: 2)

        try await storage.updateDomainsToCache_Blocking(unsDomainArray,
                                                        of: .UNS,
                                                        for: wallets)
        try await storage.updateDomainsToCache_Blocking(zilDomainsArray,
                                                        of: .ZNS,
                                                        for: wallets)
        let domains = getCachedDomainsFor(wallets: wallets)
        
        return domains
    }
    
    func getCachedDomainsPFPInfo() -> [DomainPFPInfo] {
        domainsPFPStorage.getCachedPFPs()
    }
    
    func updateDomainsPFPInfo(for domains: [DomainItem]) async -> [DomainPFPInfo] {
        let domainsPFPInfo = await loadPFPs(for: domains)
        domainsPFPStorage.saveCachedPFPInfo(domainsPFPInfo)
        return domainsPFPInfo
    }
    
    func loadPFP(for domainName: DomainName) async -> DomainPFPInfo? {
        let start = Date()
        
        if let profile = (try? await NetworkService().fetchPublicProfile(for: domainName,
                                                                         fields: [.profile, .records])) {
            Debugger.printTimeSensitiveInfo(topic: .Images,
                                            "to load \(domainName) domain pfp",
                                            startDate: start,
                                            timeout: 1)
            return DomainPFPInfo(domainName: domainName,
                                 pfpURL: profile.profile.imagePath,
                                 imageType: profile.profile.imageType)
        } else {
            Debugger.printWarning("Failed to load domains PFP info for domain \(domainName)")
            return nil
        }
    }
    
    func getAllUnMintedDomains(for email: String, securityCode: String) async throws -> [String] {
        let domainsInfo = try await NetworkService().getAllUnMintedDomains(for: email, withAccessCode: securityCode)
        let domainNames = domainsInfo.domainNames
        guard !domainNames.isEmpty else {
            throw MintingError.noDomainsToMint
        }
        return domainNames
    }
    
    func mintDomains(_ domains: [String],
                     paidDomains: [String],
                     to wallet: UDWallet,
                     userEmail: String,
                     securityCode: String) async throws -> [TransactionItem] {
        try await startMintingOfDomains(domains,
                                        paidDomains: paidDomains,
                                        to: wallet,
                                        userEmail: userEmail,
                                        securityCode: securityCode)
    }
    
    func getReferralCodeFor(domain: DomainItem) async throws -> String? {
        let profile = try await NetworkService().fetchPublicProfile(for: domain,
                                                                    fields: [.referralCode])
        return profile.referralCode
    }
    
    // Resolution
    func resolveDomainOwnerFor(domainName: DomainName) async -> HexAddress? {
        return try? await NetworkService().fetchDomainOwner(for: domainName)
    }
}

// MARK: - Private methods
private extension UDDomainsService {
   
}

// MARK: - Minting
private extension UDDomainsService {
    @discardableResult
    func startMintingOfDomains(_ domains: [String],
                               paidDomains: [String],
                               to wallet: UDWallet,
                               userEmail: String,
                               securityCode: String) async throws -> [TransactionItem] {
        
        let domainItems = createDomainItems(from: domains, for: wallet)
        let paidDomainItems = createDomainItems(from: paidDomains, for: wallet) // Legacy. Currently all domains can be minted to Polygon only and it's free.
        
        do {
            let txs = try await NetworkService().mint(domains: domainItems,
                                                      with: userEmail,
                                                      code: securityCode,
                                                      stripeIntent: nil)
            try? await Task.sleep(seconds: 0.1)
            return txs
        } catch {
            let description = error.getTypedDescription()
            Debugger.printFailure(description)
            throw error
        }
    }
    
    func createDomainItems(from domainNames: [String], for wallet: UDWallet) -> [DomainItem] {
        // For now ALL domains minted on polygon.
        let namingService: NamingService = .UNS
        
        let domains: [DomainItem] = domainNames.compactMap({
            guard let ownerAddress = wallet.getAddress(for: namingService) else { return nil }
            let blockchain: BlockchainType = .Matic
            
            return DomainItem (name: $0,
                               ownerWallet: ownerAddress,
                               blockchain: blockchain,
                               status: .claiming)
        })
        return domains
    }
}

// MARK: - Private methods
private extension UDDomainsService {
    func loadPFPs(for domains: [DomainItem]) async -> [DomainPFPInfo] {
        guard !domains.isEmpty else { return  [] }
        
        let start = Date()
        var domainsPFPInfo = [DomainPFPInfo]()
        
        await withTaskGroup(of: DomainPFPInfo?.self, body: { group in
            for domain in domains {
                group.addTask {
                    if let pfpInfo = await self.loadPFP(for: domain.name) {
                        return pfpInfo
                    } else {
                        return nil
                    }
                }
            }
            
            for await pfpInfo in group {
                if let pfpInfo {
                    domainsPFPInfo.append(pfpInfo)
                }
            }
        })
        Debugger.printTimeSensitiveInfo(topic: .Domain,
                                        "to load \(domains.count) domains pfps",
                                        startDate: start,
                                        timeout: 3)
        
        return domainsPFPInfo
    }
}

enum UDDomainsError: Error {
    case updateDomainsList(_ error: Error)
    case fetchZilDomains(_ error: Error)
    
    var errorMessage: String {
        switch self {
        case .updateDomainsList(let error):
            return "Failed to load domains: \(error.localizedDescription)"
        case .fetchZilDomains(let error):
            return "Failed to load ZIL domains: \(error.localizedDescription)"
        }
    }
}

enum MintingError: String, RawValueLocalizable, Error {
    case noDomainsToMint = "NO_DOMAINS_TO_MINT"
}
