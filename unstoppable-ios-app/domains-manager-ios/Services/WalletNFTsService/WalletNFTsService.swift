//
//  WalletNFTsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.03.2023.
//

import Foundation

protocol WalletNFTsServiceProtocol {
    func getImageNFTsFor(domainName: String) async throws -> [NFTModel]
    @discardableResult
    func refreshNFTsFor(domainName: String) async throws -> [NFTModel]
    
    // Listeners
    func addListener(_ listener: WalletNFTsServiceListener)
    func removeListener(_ listener: WalletNFTsServiceListener)
}

protocol WalletNFTsServiceListener: AnyObject {
    func didRefreshNFTs(_ nfts: [NFTModel], for domainName: DomainName)
}

final class WalletNFTsServiceListenerHolder: Equatable {
    
    weak var listener: WalletNFTsServiceListener?
    
    init(listener: WalletNFTsServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: WalletNFTsServiceListenerHolder, rhs: WalletNFTsServiceListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}

final class WalletNFTsService {
    
    private var dataHolder = DataHolder()
    private let limit = 50
    private var listenerHolders: [WalletNFTsServiceListenerHolder] = []

    init() {
        loadCachedNFTs()
    }
    
}

// MARK: - WalletNFTsServiceProtocol
extension WalletNFTsService: WalletNFTsServiceProtocol {
    func getImageNFTsFor(domainName: String) async throws -> [NFTModel] {
        if let cache = await dataHolder.nftsCache[domainName] {
            let isRefreshed = await dataHolder.isAddressRefreshed(domainName)
            if !isRefreshed {
                Task.detached(priority: .high) {
                    try? await self.refreshNFTsFor(domainName: domainName)
                }
            }
            return cache
        }
        
        let nfts = try await createTaskAndLoadAllNFTsFor(domainName: domainName)
        
        return nfts
    }
    
    @discardableResult
    func refreshNFTsFor(domainName: String) async throws -> [NFTModel] {
        try await self.createTaskAndLoadAllNFTsFor(domainName: domainName)
    }
    
    // Listeners
    func addListener(_ listener: WalletNFTsServiceListener) {
        if !listenerHolders.contains(where: { $0.listener === listener }) {
            listenerHolders.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: WalletNFTsServiceListener) {
        listenerHolders.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - Private methods
private extension WalletNFTsService {
    func loadCachedNFTs() {
        Task {
            let nfts = DomainNFTsStorage.instance.getCachedNFTs()
            let nftsByDomain = [DomainName : [NFTModel]].init(grouping: nfts, by: { $0.address ?? "" })
        
            for (domainName, nfts) in nftsByDomain {
                await dataHolder.set(nfts: nfts, forDomain: domainName, isRefreshed: false)
            }
        }
    }
    
    @discardableResult
    func createTaskAndLoadAllNFTsFor(domainName: HexAddress) async throws -> [NFTModel] {
        if let task = await dataHolder.currentAsyncProcess[domainName] {
            return try await task.value
        }
        
        let task: Task<[NFTModel], Error> = Task.detached(priority: .high) {
            try await self.loadAllNFTsFor(domainName: domainName)
        }
        
        await dataHolder.addAsyncProcessTask(task, for: domainName)
        let nfts = try await task.value
        await dataHolder.addAsyncProcessTask(nil, for: domainName)
        
        return nfts
    }
  
    func loadAllNFTsFor(domainName: HexAddress) async throws -> [NFTModel] {        
        let response = try await makeGetNFTsRequest(domainName: domainName, cursor: nil, chains: [])
        
        var nfts = [NFTModel]()
        
        try await withThrowingTaskGroup(of: [NFTModel].self, body: { group in
            for chainResponse in response.allChainsResponses {
                group.addTask {
                    return try await self.loadAllNFTsFor(chainResponse: chainResponse, domainName: domainName)
                }
            }
            
            for try await chainNFTs in group {
                nfts += chainNFTs
            }
        })
        
        nfts = nfts.clearingInvalidNFTs()
        
        await dataHolder.set(nfts: nfts, forDomain: domainName, isRefreshed: true)
        await didRefreshNFTs(nfts, for: domainName)
        
        return nfts
    }
    
    func loadAllNFTsFor(chainResponse: NFTModelsForChainResponse?, domainName: String) async throws -> [NFTModel] {
        guard let chainResponse else { return [] }
        guard let chain = chainResponse.chain else {
            Debugger.printFailure("Response chain is not specified", critical: true)
            return []
        }
        
        if chainResponse.nfts.count >= limit,
           let cursor = chainResponse.cursor {
            let nextResponse = try await makeGetNFTsRequest(domainName: domainName, cursor: cursor, chains: [chain])
            
            guard var nextChainResponse = nextResponse.chainResponseFor(chain: chain) else {
                Debugger.printFailure("Couldn't find request chain in response")
                return chainResponse.nfts
            }
            
            nextChainResponse.nfts += chainResponse.nfts
            return try await loadAllNFTsFor(chainResponse: nextChainResponse, domainName: domainName)
        } else {
            return chainResponse.nfts
        }
    }
    
    func makeGetNFTsRequest(domainName: String, cursor: String?, chains: [NFTModelChain]) async throws -> NFTsResponse {
        Debugger.printInfo(topic: .NFT, "Will get NFTs for domain: \(domainName), cursor: \(cursor ?? "Nil"), chains: \(chains.map({ $0.rawValue} ))")
        let request = NFTsAPIRequestBuilder().nftsFor(domainName: domainName,
                                                      limit: limit,
                                                      cursor: cursor,
                                                      chains: chains)
        let data = try await NetworkService().fetchData(for: request.url,
                                                        method: .get,
                                                        extraHeaders: NetworkConfig.stagingAccessKeyIfNecessary)
        guard var response = NFTsResponse.objectFromData(data, using: .convertFromSnakeCase) else { throw NetworkLayerError.responseFailedToParse }
        response.prepare()
        Debugger.printInfo(topic: .NFT, "Did get NFTs \(response.nfts.count) for domain: \(domainName), cursor: \(cursor ?? "Nil"), chains: \(chains.map({ $0.rawValue} ))")

        return response
    }
    
    func didRefreshNFTs(_ nfts: [NFTModel], for domainName: DomainName) async {
        listenerHolders.forEach { holder in
            holder.listener?.didRefreshNFTs(nfts, for: domainName)
        }
        
        let allNFTs = await dataHolder.getAllNFTs()
        DomainNFTsStorage.instance.saveCachedNFTs(allNFTs)
    }
}

// MARK: - DataHolder
private extension WalletNFTsService {
    actor DataHolder {
        var nftsCache: [DomainName : [NFTModel]] = [:]
        var refreshedAddresses: Set<DomainName> = []
        var currentAsyncProcess = [DomainName : Task<[NFTModel], Error>]()

        func set(nfts: [NFTModel],
                 forDomain domainName: DomainName,
                 isRefreshed: Bool) {
            nftsCache[domainName] = nfts
            if isRefreshed {
                refreshedAddresses.insert(domainName)
            }
        }
        
        func isAddressRefreshed(_ domainName: DomainName) -> Bool {
            refreshedAddresses.contains(domainName)
        }
        
        func addAsyncProcessTask(_ task: Task<[NFTModel], Error>?, for domainName: DomainName) {
            currentAsyncProcess[domainName] = task
        }
        
        func getAllNFTs() -> [NFTModel] {
            nftsCache.flatMap({ $0.value })
        }
    }
}

private struct NFTsResponse: Codable {
    var ETH: NFTModelsForChainResponse?
    var MATIC: NFTModelsForChainResponse?
    var SOL: NFTModelsForChainResponse?
    var ADA: NFTModelsForChainResponse?
    var HBAR: NFTModelsForChainResponse?
    
    var allChainsResponses: [NFTModelsForChainResponse] { [ETH, MATIC, SOL, ADA, HBAR].compactMap({ $0 }) }
    
    var nfts: [NFTModel] { allChainsResponses.flatMap({ $0.nfts }) }
    
    mutating func prepare() {
        ETH?.prepareWith(chain: .ETH)
        MATIC?.prepareWith(chain: .MATIC)
        SOL?.prepareWith(chain: .SOL)
        ADA?.prepareWith(chain: .ADA)
        HBAR?.prepareWith(chain: .HBAR)
    }
    
    func chainResponseFor(chain: NFTModelChain) -> NFTModelsForChainResponse? {
        switch chain {
        case .ETH: return ETH
        case .MATIC: return MATIC
        case .SOL: return SOL
        case .ADA: return ADA
        case .HBAR: return HBAR
        }
    }
}

private struct NFTModelsForChainResponse: Codable {
    var cursor: String?
    var enabled: Bool
    var verified: Bool?
    var address: String
    var nfts: [NFTModel]
    var chain: NFTModelChain?
    
    mutating func prepareWith(chain: NFTModelChain) {
        self.chain = chain
        
        for i in 0..<nfts.count {
            nfts[i].chain = chain
            nfts[i].address = address
        }
    }
}
