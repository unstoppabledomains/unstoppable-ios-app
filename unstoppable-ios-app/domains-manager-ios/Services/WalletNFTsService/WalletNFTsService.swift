//
//  WalletNFTsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.03.2023.
//

import Foundation

protocol WalletNFTsServiceProtocol {
    func getImageNFTsFor(wallet: UDWallet) async throws
}

final class WalletNFTsService {
    
    
    
}

// MARK: - WalletNFTsServiceProtocol
extension WalletNFTsService: WalletNFTsServiceProtocol {
    func getImageNFTsFor(wallet: UDWallet) async throws {
        let domains = await appContext.dataAggregatorService.getDomainItems().filter({ $0.isOwned(by: [wallet] )})
        guard let domain = domains.first else { return }
        let request = NFTsAPIRequestBuilder().nftsFor(domainName: domain.name, cursor: nil, chains: nil)
        let data = try await NetworkService().fetchData(for: request.url,
                                                        method: .get,
                                                        extraHeaders: NetworkConfig.stagingAccessKeyIfNecessary)
        let response = try NFTImagesResponse.objectFromData(data, using: .convertFromSnakeCase)
    }
}

struct NFTImagesResponse: Codable {
    var ETH: NFTImagesForChainResponse?
    var MATIC: NFTImagesForChainResponse?
    var SOL: NFTImagesForChainResponse?
    var ADA: NFTImagesForChainResponse?
    var HBAR: NFTImagesForChainResponse?
}

enum NFTImageChain: String {
    case ETH
    case MATIC
    case SOL
    case ADA
    case HBAR
}

struct NFTImagesForChainResponse: Codable {
    var cursor: String?
    var enabled: Bool
    var verified: Bool?
    var address: String
    var nfts: [NFTResponse]
    
    struct NFTResponse: Codable {
        var name: String?
        var description: String?
        var imageUrl: String?
        var `public`: Bool
        var videoUrl: String?
        var link: String?
        var tags: [String]
        var collection: String?
        var mint: String?
    }
}

struct NFTImage {
    let name: String
    let chainId: Int
    let ownerOf: String
    let tokenId: String
    let category: String
    let imageUrl: String
    let tokenAddress: String
    let description: String?
}
