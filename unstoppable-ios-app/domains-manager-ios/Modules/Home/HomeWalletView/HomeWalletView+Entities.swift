//
//  HomeWalletView+Entities.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import UIKit

extension HomeWalletView {
    struct TokenDescription: Hashable, Identifiable {
        var id: String { symbol }
        
        let symbol: String
        let name: String
        let balance: Double
        var marketUsd: Double?
        var icon: UIImage? = nil
        var fiatValue: Double? {
            if let marketUsd {
                return marketUsd * balance
            }
            return nil
        }
        
        static let iconSize: InitialsView.InitialsSize = .default
        static let iconStyle: InitialsView.Style = .gray
        
        init(walletBalance: ProfileWalletBalance) {
            self.symbol = walletBalance.symbol
            self.name = walletBalance.name
            self.balance = walletBalance.balance
            self.marketUsd = walletBalance.value?.marketUsd
            self.icon = appContext.imageLoadingService.cachedImage(for: .currencyTicker(symbol,
                                                                                        size: TokenDescription.iconSize,
                                                                                        style: TokenDescription.iconStyle))
        }
        
        init(symbol: String, name: String, balance: Double, marketUsd: Double? = nil, icon: UIImage? = nil) {
            self.symbol = symbol
            self.name = name
            self.balance = balance
            self.marketUsd = marketUsd
            self.icon = icon
        }
        
        func loadIconIfNeeded(iconUpdated: @escaping (UIImage?)->()) {
            guard icon == nil else { return }
            
            Task {
                let size = TokenDescription.iconSize
                let style = TokenDescription.iconStyle
                let ticker = symbol
                let initials = await appContext.imageLoadingService.loadImage(from: .initials(ticker,
                                                                                              size: size,
                                                                                              style: style),
                                                                              downsampleDescription: nil)
                iconUpdated(initials)
                
                
                if let icon = await appContext.imageLoadingService.loadImage(from: .currencyTicker(ticker,
                                                                                                   size: size,
                                                                                                   style: style),
                                                                             downsampleDescription: .icon) {
                    iconUpdated(icon)
                }
            }
        }
        
        static func mock() -> [TokenDescription] {
            let tickers = ["ETH", "MATIC"]
            //            var tickers = ["ETH", "MATIC", "USDC", "1INCH",
            //                           "SOL", "USDT", "DOGE", "DAI"]
            //            tickers += ["AAVE", "ADA", "AKT", "APT", "ARK", "CETH"]
            var tokens = [TokenDescription]()
            for ticker in tickers {
                let value = Double(arc4random_uniform(10000))
                let token = TokenDescription(symbol: ticker,
                                             name: ticker,
                                             balance: value,
                                             marketUsd: value)
                tokens.append(token)
                
            }
            
            return tokens
        }
    }
}

extension HomeWalletView {
    struct NFTsCollectionDescription: Hashable, Identifiable {
        var id: String { collectionName }

        let collectionName: String
        let nfts: [NFTDescription]
        
        static func mock() -> [NFTsCollectionDescription] {
            let names = ["Azuki", "Mutant Ape Yacht Club", "DeGods", "Grunchy Tigers"]
            var collections = [NFTsCollectionDescription]()
            
            for name in names {
                
                let collection = NFTsCollectionDescription(collectionName: name, nfts: [.mock(),
                                                                                        .mock(),
                                                                                        .mock(),
                                                                                        .mock(),
                                                                                        .mock()])
                collections.append(collection)
            }
            
            return collections
        }
    }
    
    struct NFTDescription: Hashable, Identifiable {
        var id: String { mint ?? UUID().uuidString }
        
        let name: String?
        let description: String?
        let imageUrl: String?
        let videoUrl: String?
        let link: String?
        let tags: [String]
        let collection: String?
        let mint: String?
        var chain: NFTModelChain?
        var address: String?
        
        var isDomainNFT: Bool { tags.contains("domain") }
        var isUDDomainNFT: Bool {
            if isDomainNFT,
               let tld = name?.components(separatedBy: ".").last,
               User.instance.getAppVersionInfo().tlds.contains(tld) {
                return true
            }
            return false
        }
        
        var chainIcon: UIImage { chain?.icon ?? .ethereumIcon }
        
        init(nftModel: NFTModel) {
            self.name = nftModel.name
            self.description = nftModel.description
            self.imageUrl = nftModel.imageUrl
            self.videoUrl = nftModel.videoUrl
            self.link = nftModel.link
            self.tags = nftModel.tags
            self.collection = nftModel.collection
            self.mint = nftModel.mint
            self.chain = nftModel.chain
            self.address = nftModel.address
        }

        init(name: String? = nil, description: String? = nil, imageUrl: String? = nil, videoUrl: String? = nil, link: String? = nil, tags: [String], collection: String? = nil, mint: String? = nil, chain: NFTModelChain? = nil, address: String? = nil) {
            self.name = name
            self.description = description
            self.imageUrl = imageUrl
            self.videoUrl = videoUrl
            self.link = link
            self.tags = tags
            self.collection = collection
            self.mint = mint
            self.chain = chain
            self.address = address
        }
        
        static func mock() -> NFTDescription {
            .init(name: "Name", tags: [], mint: UUID().uuidString)
        }
    }
}
