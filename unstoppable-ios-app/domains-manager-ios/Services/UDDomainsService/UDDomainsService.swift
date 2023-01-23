//
//  UDDomainsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import Foundation
import PromiseKit

final class UDDomainsService {
        
    private let storage: Storage = Storage.instance
    
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
        Debugger.printWarning("\(String.itTook(from: start)) to load \((combinedDomains).count) domains for \(wallets.count) wallets")

        try await storage.updateDomainsToCache_Blocking(unsDomainArray,
                                                        of: .UNS,
                                                        for: wallets)
        try await storage.updateDomainsToCache_Blocking(zilDomainsArray,
                                                        of: .ZNS,
                                                        for: wallets)
        let domains = getCachedDomainsFor(wallets: wallets)
        
        return domains
    }
    
    func updatePFP(for domains: [DomainItem]) async throws -> [DomainItem] {
        let domainsWithPFPs = await loadPFPs(for: domains)
        try await storage.updateDomainsPFPToCache_Blocking(domainsWithPFPs)
        return domainsWithPFPs
    }
    
    func getAllUnMintedDomains(for email: String, securityCode: String) async throws -> [String] {
        try await withSafeCheckedThrowingContinuation({ completion in
            getAllUnMintedDomains(for: email, securityCode: securityCode) { result in
                switch result {
                case .fulfilled(let domainNames):
                    completion(.success(domainNames))
                case .rejected(let error):
                    completion(.failure(error))
                }
            }
        })
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
}

// MARK: - Private methods
private extension UDDomainsService {
    func getAllUnMintedDomains(for email: String, securityCode: String, completion: @escaping ((Result<[String]>)->())) {
        NetworkService().getAllUnmintedDomains(for: email, withAccessCode: securityCode)
            .then { (result: NetworkService.DomainsInfo) -> Promise<NetworkService.DomainsInfo> in
                Promise {
                    guard result.domainNames.count > 0 else {
                        $0.reject(MintingError.noDomainsToMint)
                        return
                    }
                    $0.fulfill(result)
                }
            }
            .done { result in
                completion(.fulfilled(result.domainNames))
            }
            .catch({ error in
                completion(.rejected(error))
            })
    }
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
        let paidDomainItems = createDomainItems(from: paidDomains, for: wallet)
        
        return try await withSafeCheckedThrowingContinuation({ completion in
            doMintConcurrent(domainsMinting: domainItems,
                             paidDomains: paidDomainItems,
                             userEmail: userEmail,
                             securityCode: securityCode,
                             didStartMintingCallback: { }) { result in
                switch result {
                case .fulfilled(let txs):
                    completion(.success(txs))
                case .rejected(let error):
                    completion(.failure(error))
                }
            }
        })
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
    
    func doMintConcurrent(domainsMinting: [DomainItem],
                          paidDomains: [DomainItem],
                          userEmail: String,
                          securityCode: String,
                          didStartMintingCallback: @escaping ()->Void,
                          completionBlock: @escaping ((Result<[TransactionItem]>) -> Void)) {
        
        let waitAtLeast = after(seconds: 0.1)
        NetworkService().mint(domains: domainsMinting,
                              with: userEmail,
                              code: securityCode,
                              stripeIntent: nil)
        .done { txs in
            let newMintingDomains: [DomainItem] = domainsMinting.map {
                let domainName = $0.name
                guard let mintingTx = txs.first(where: {tx in domainName == tx.domainName} ) else { return $0 }
                var domain = $0
                domain.claimingTxId = mintingTx.id
                return domain
            }
            
            // needed for backend simulation
            completionBlock(.fulfilled(txs))
        }
        .then { waitAtLeast }
        .catch { err in
            
            let description = err.getTypedDescription()
            Debugger.printFailure(description)
            completionBlock(.rejected(err))
        }
    }
}

// MARK: - Private methods
private extension UDDomainsService {
    actor DomainsHolder {
        var domains: [DomainItem]
        init(domains: [DomainItem]) {
            self.domains = domains
        }
        
        func addDomain(_ domain: DomainItem) {
            domains.append(domain)
        }
    }
    
    func loadPFPs(for domains: [DomainItem]) async -> [DomainItem] {
        guard !domains.isEmpty else { return  domains }
        
        let start = Date()
        let networkService = NetworkService()
        let holder = DomainsHolder(domains: [])
        await withTaskGroup(of: Void.self) { group in
            for (i, domain) in domains.enumerated() {
                
                if i >= 5 {
                    await group.next()
                }
                
                group.addTask {
                    if let profile = (try? await networkService.fetchPublicProfile(for: domain, fields: [.profile, .records])) {
                        var domain = domain
                        domain.pfpURL = profile.profile.imagePath
                        domain.imageType = profile.profile.imageType
                        await holder.addDomain(domain)
                    } else {
                        Debugger.printFailure("Failed to load domains PFP info for domain \(domain.name)", critical: false)
                        await holder.addDomain(domain)
                    }
                }
            }
            
            await group.waitForAll()
        }
        Debugger.printWarning("\(String.itTook(from: start)) to load \(domains.count) domains pfps")
        
        return await holder.domains
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

struct DomainNFTImageInfo: Codable {
    
    let domain: String
    let records: Records?
    
    var imageValue: String? {
        if let imageValue = records?.imageValue,
           !imageValue.isEmpty {
            return imageValue
        }
        return nil
    }
    
    struct Records: Codable {
        let imageValue: String?
        
        enum CodingKeys: String, CodingKey {
            case imageValue = "social.picture.value"
        }
    }
}

struct DomainNonNFTImageInfo: Codable {
  
    let domainName: String
    let imagePath: String?
    
    var imagePathValue: String? {
        if let imagePath = imagePath,
           !imagePath.isEmpty {
            return imagePath
        }
        return nil
    }
    
}

enum MintingError: String, RawValueLocalizable, Error {
    case noDomainsToMint = "NO_DOMAINS_TO_MINT"
}
