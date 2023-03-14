//
//  WalletNFTsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.03.2023.
//

import UIKit

protocol WalletNFTsServiceProtocol {
    func getImageNFTsFor(wallet: UDWallet) async throws -> [NFTResponse]
}

final class WalletNFTsService {
    
    private var dataHolder = DataHolder()
    private let limit = 50
    private var currentAsyncProcess = [HexAddress : Task<[NFTResponse], Error>]()

}

// MARK: - WalletNFTsServiceProtocol
extension WalletNFTsService: WalletNFTsServiceProtocol {
    func getImageNFTsFor(wallet: UDWallet) async throws -> [NFTResponse] {
        let walletAddress = wallet.address
        
        if let cache = await dataHolder.nftsCache[walletAddress] {
            return cache
        }
        
        if let task = currentAsyncProcess[walletAddress] {
            return try await task.value
        }
        
        let task: Task<[NFTResponse], Error> = Task.detached(priority: .high) {
            let domains = await appContext.dataAggregatorService.getDomainItems().filter({ $0.isOwned(by: [wallet] )})
            guard let domain = domains.first else { return [] }
            let domainName = domain.name
            
            let response = try await self.makeGetNFTsRequest(domainName: domainName, cursor: nil, chains: [])
            
            var nfts = [NFTResponse]()
            
            try await withThrowingTaskGroup(of: [NFTResponse].self, body: { group in
                for chainResponse in response.allChainsResponses {
                    group.addTask {
                        return try await self.loadAllNFTsFor(chainResponse: chainResponse, domainName: domainName)
                    }
                }
                
                for try await chainNFTs in group {
                    nfts += chainNFTs
                }
            })
            
            await self.dataHolder.set(nfts: nfts, forWallet: wallet.address)
            
            return nfts
        }
        
        currentAsyncProcess[walletAddress] = task
        let nfts = try await task.value
        currentAsyncProcess[walletAddress] = nil
        
        return nfts
    }
}

// MARK: - Private methods
private extension WalletNFTsService {
    func didRefreshNFTs(_ nfts: [NFTResponse], for walletAddress: HexAddress) {
        
    }
    
    func loadAllNFTsFor(chainResponse: NFTImagesForChainResponse?, domainName: String) async throws -> [NFTResponse] {
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
    
    func makeGetNFTsRequest(domainName: String, cursor: String?, chains: [NFTImageChain]) async throws -> NFTImagesResponse {
        Debugger.printInfo(topic: .NFT, "Will get NFTs for domain: \(domainName), cursor: \(cursor ?? "Nil"), chains: \(chains.map({ $0.rawValue} ))")
        let request = NFTsAPIRequestBuilder().nftsFor(domainName: domainName,
                                                      limit: limit,
                                                      cursor: cursor,
                                                      chains: chains)
        let data = try await NetworkService().fetchData(for: request.url,
                                                        method: .get,
                                                        extraHeaders: NetworkConfig.stagingAccessKeyIfNecessary)
        guard var response = NFTImagesResponse.objectFromData(data, using: .convertFromSnakeCase) else { throw NetworkLayerError.responseFailedToParse }
        response.prepare()
        Debugger.printInfo(topic: .NFT, "Did get NFTs \(response.nfts.count) for domain: \(domainName), cursor: \(cursor ?? "Nil"), chains: \(chains.map({ $0.rawValue} ))")

        return response
    }
}

// MARK: - DataHolder
private extension WalletNFTsService {
    actor DataHolder {
        var nftsCache: [HexAddress : [NFTResponse]] = [:]
        
        func set(nfts: [NFTResponse], forWallet walletAddress: HexAddress) {
            nftsCache[walletAddress] = nfts
        }
    }
}

struct NFTImagesResponse: Codable {
    var ETH: NFTImagesForChainResponse?
    var MATIC: NFTImagesForChainResponse?
    var SOL: NFTImagesForChainResponse?
    var ADA: NFTImagesForChainResponse?
    var HBAR: NFTImagesForChainResponse?
    
    var allChainsResponses: [NFTImagesForChainResponse] { [ETH, MATIC, SOL, ADA, HBAR].compactMap({ $0 }) }
    
    var nfts: [NFTResponse] { allChainsResponses.flatMap({ $0.nfts }) }
    
    mutating func prepare() {
        ETH?.prepareWith(chain: .ETH)
        MATIC?.prepareWith(chain: .MATIC)
        SOL?.prepareWith(chain: .SOL)
        ADA?.prepareWith(chain: .ADA)
        HBAR?.prepareWith(chain: .HBAR)
    }
    
    func chainResponseFor(chain: NFTImageChain) -> NFTImagesForChainResponse? {
        switch chain {
        case .ETH: return ETH
        case .MATIC: return MATIC
        case .SOL: return SOL
        case .ADA: return ADA
        case .HBAR: return HBAR
        }
    }
}

struct NFTImagesForChainResponse: Codable {
    var cursor: String?
    var enabled: Bool
    var verified: Bool?
    var address: String
    var nfts: [NFTResponse]
    var chain: NFTImageChain?
    
    mutating func prepareWith(chain: NFTImageChain) {
        self.chain = chain
        
        for i in 0..<nfts.count {
            nfts[i].chain = chain
            nfts[i].address = address
        }
    }
}

struct NFTResponse: Codable, Hashable {
    var name: String?
    var description: String?
    var imageUrl: String?
    var `public`: Bool
    var videoUrl: String?
    var link: String?
    var tags: [String]
    var collection: String?
    var mint: String?
    var chain: NFTImageChain?
    var address: String?
    
    var isDomainNFT: Bool { tags.contains("domain") }
    
    var chainIcon: UIImage { chain?.icon ?? .ethereumIcon }
}

enum NFTImageChain: String, Hashable, Codable, CaseIterable {
    case ETH
    case MATIC
    case SOL
    case ADA
    case HBAR
    
    var icon: UIImage {
        switch self {
        case .ETH:
            return .ethereumIcon
        case .MATIC:
            return .polygonIcon
        case .SOL:
            return .ethereumIcon
        case .ADA:
            return .ethereumIcon
        case .HBAR:
            return .ethereumIcon
        }
    }
}
