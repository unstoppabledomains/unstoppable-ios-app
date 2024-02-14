//
//  WalletNFTsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.03.2023.
//

import Foundation

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
    func fetchNFTsFor(walletAddress: HexAddress) async throws -> [NFTModel] {
        try await self.createTaskAndLoadAllNFTsFor(wallet: walletAddress)
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
            let nftsByDomain = [HexAddress : [NFTModel]].init(grouping: nfts, by: { $0.address ?? "" })
        
            for (wallet, nfts) in nftsByDomain {
                await dataHolder.set(nfts: nfts, forWallet: wallet, isRefreshed: false)
            }
        }
    }
    
    @discardableResult
    func createTaskAndLoadAllNFTsFor(wallet: HexAddress) async throws -> [NFTModel] {
        if let task = await dataHolder.currentAsyncProcess[wallet] {
            return try await task.value
        }
        
        let task: Task<[NFTModel], Error> = Task.detached(priority: .high) {
            try await self.loadAllNFTsFor(wallet: wallet)
        }
        
        do {
            await dataHolder.addAsyncProcessTask(task, for: wallet)
            let nfts = try await task.value
            await dataHolder.addAsyncProcessTask(nil, for: wallet)
            return nfts
        } catch {
            await dataHolder.addAsyncProcessTask(nil, for: wallet)
            throw error
        }
    }
  
    func loadAllNFTsFor(wallet: HexAddress) async throws -> [NFTModel] {
        let response = try await makeGetNFTsRequest(wallet: wallet, cursor: nil, chains: [])
        
        var nfts = [NFTModel]()
        
        try await withThrowingTaskGroup(of: [NFTModel].self, body: { group in
            for chainResponse in response.allChainsResponses {
                group.addTask {
                    return try await self.loadAllNFTsFor(chainResponse: chainResponse, wallet: wallet)
                }
            }
            
            for try await chainNFTs in group {
                nfts += chainNFTs
            }
        })
        
        nfts = nfts.clearingInvalidNFTs()
        
        await dataHolder.set(nfts: nfts, forWallet: wallet, isRefreshed: true)
        await didRefreshNFTs(nfts, for: wallet)
        
        return nfts
    }
    
    func loadAllNFTsFor(chainResponse: NFTModelsForChainResponse?, wallet: String) async throws -> [NFTModel] {
        guard let chainResponse else { return [] }
        guard let chain = chainResponse.chain else {
            Debugger.printFailure("Response chain is not specified", critical: true)
            return []
        }
        
        if chainResponse.nfts.count >= limit,
           let cursor = chainResponse.cursor {
            let nextResponse = try await makeGetNFTsRequest(wallet: wallet, cursor: cursor, chains: [chain])
            
            guard var nextChainResponse = nextResponse.chainResponseFor(chain: chain) else {
                Debugger.printFailure("Couldn't find request chain in response")
                return chainResponse.nfts
            }
            
            nextChainResponse.nfts += chainResponse.nfts
            return try await loadAllNFTsFor(chainResponse: nextChainResponse, wallet: wallet)
        } else {
            return chainResponse.nfts
        }
    }
    
    func makeGetNFTsRequest(wallet: String, cursor: String?, chains: [NFTModelChain]) async throws -> NFTsResponse {
        Debugger.printInfo(topic: .NFT, "Will get NFTs for domain: \(wallet), cursor: \(cursor ?? "Nil"), chains: \(chains.map({ $0.rawValue} ))")
        let request = NFTsAPIRequestBuilder().nftsFor(wallet: wallet,
                                                      limit: limit,
                                                      cursor: cursor,
                                                      chains: chains)
        let data = try await NetworkService().fetchData(for: request.url,
                                                        method: .get,
                                                        extraHeaders: request.headers)
        guard var response = NFTsResponse.objectFromData(data, dateDecodingStrategy: .nftDateDecodingStrategy()) else { throw NetworkLayerError.responseFailedToParse }
        response.prepare()
        Debugger.printInfo(topic: .NFT, "Did get NFTs \(response.nfts.count) for domain: \(wallet), cursor: \(cursor ?? "Nil"), chains: \(chains.map({ $0.rawValue} ))")

        return response
    }
    
    func didRefreshNFTs(_ nfts: [NFTModel], for wallet: HexAddress) async {
        listenerHolders.forEach { holder in
            holder.listener?.didRefreshNFTs(nfts, for: wallet)
        }
        
        let allNFTs = await dataHolder.getAllNFTs()
        DomainNFTsStorage.instance.saveCachedNFTs(allNFTs)
    }
}

// MARK: - DataHolder
private extension WalletNFTsService {
    actor DataHolder {
        var nftsCache: [HexAddress : [NFTModel]] = [:]
        var refreshedAddresses: Set<HexAddress> = []
        var currentAsyncProcess = [HexAddress : Task<[NFTModel], Error>]()

        func set(nfts: [NFTModel],
                 forWallet wallet: HexAddress,
                 isRefreshed: Bool) {
            nftsCache[wallet] = nfts
            if isRefreshed {
                refreshedAddresses.insert(wallet)
            }
        }
        
        func isAddressRefreshed(_ walletAddress: HexAddress) -> Bool {
            refreshedAddresses.contains(walletAddress)
        }
        
        func addAsyncProcessTask(_ task: Task<[NFTModel], Error>?, for wallet: HexAddress) {
            currentAsyncProcess[wallet] = task
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
    var verified: Bool?
    var address: String
    @DecodeIgnoringFailed
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
