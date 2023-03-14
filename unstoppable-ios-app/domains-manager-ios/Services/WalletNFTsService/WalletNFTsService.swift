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
    
}

// MARK: - WalletNFTsServiceProtocol
extension WalletNFTsService: WalletNFTsServiceProtocol {
    func getImageNFTsFor(wallet: UDWallet) async throws -> [NFTResponse] {
        if let cache = await dataHolder.nftsCache[wallet.address] {
            return cache
        }
        
        let domains = await appContext.dataAggregatorService.getDomainItems().filter({ $0.isOwned(by: [wallet] )})
        guard let domain = domains.first else { return [] }
        let request = NFTsAPIRequestBuilder().nftsFor(domainName: domain.name, cursor: nil, chains: nil)
        let data = try await NetworkService().fetchData(for: request.url,
                                                        method: .get,
                                                        extraHeaders: NetworkConfig.stagingAccessKeyIfNecessary)
        guard var response = NFTImagesResponse.objectFromData(data, using: .convertFromSnakeCase) else { throw NetworkLayerError.responseFailedToParse }
        response.setChains()
        let nfts = response.nfts
        await dataHolder.set(nfts: nfts, forWallet: wallet.address)
        
        return nfts
    }
}

// MARK: - Private methods
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
    
    var allChainsResponses: [NFTImagesForChainResponse?] { [ETH, MATIC, SOL, ADA, HBAR] }
    
    var nfts: [NFTResponse] { allChainsResponses.compactMap({ $0 }).flatMap({ $0.nfts }) }
    
    mutating func setChains() {
        ETH?.setChain(.ETH)
        MATIC?.setChain(.MATIC)
        SOL?.setChain(.SOL)
        ADA?.setChain(.ADA)
        HBAR?.setChain(.HBAR)
    }
}

enum NFTImageChain: String, Hashable, Codable {
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

struct NFTImagesForChainResponse: Codable {
    var cursor: String?
    var enabled: Bool
    var verified: Bool?
    var address: String
    var nfts: [NFTResponse]
    
    mutating func setChain(_ chain: NFTImageChain) {
        for i in 0..<nfts.count {
            nfts[i].chain = chain
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
    
    var isDomainNFT: Bool { tags.contains("domain") }
    
    var chainIcon: UIImage { chain?.icon ?? .ethereumIcon }
}
