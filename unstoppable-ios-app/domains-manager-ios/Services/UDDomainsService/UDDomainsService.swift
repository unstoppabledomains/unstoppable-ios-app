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
    
    func getCachedDomainsPFPInfo() -> [DomainPFPInfo] {
        domainsPFPStorage.getCachedPFPs()
    }
    
    func updateDomainsPFPInfo(for domains: [DomainItem]) async -> [DomainPFPInfo] {
        let domainsPFPInfo = await loadPFPs(for: domains)
        domainsPFPStorage.saveCachedPFPInfo(domainsPFPInfo)
        return domainsPFPInfo
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
    func loadPFPs(for domains: [DomainItem]) async -> [DomainPFPInfo] {
        guard !domains.isEmpty else { return  [] }
        
        let start = Date()
        let networkService = NetworkService()
        var domainsPFPInfo = [DomainPFPInfo]()
        
        await withTaskGroup(of: DomainPFPInfo?.self, body: { group in
            for domain in domains {
                group.addTask {
                    if let profile = (try? await networkService.fetchPublicProfile(for: domain,
                                                                                   fields: [.profile, .records])) {
                        return DomainPFPInfo(domainName: domain.name,
                                             pfpURL: profile.profile.imagePath,
                                             imageType: profile.profile.imageType)
                    } else {
                        Debugger.printFailure("Failed to load domains PFP info for domain \(domain.name)", critical: false)
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
        
        Debugger.printWarning("\(String.itTook(from: start)) to load \(domains.count) domains pfps")
        
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
