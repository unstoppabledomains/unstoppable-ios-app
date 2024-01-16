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
        private(set) var isSkeleton: Bool = false
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
        
        static func createSkeletonEntity() -> TokenDescription {
            var token = TokenDescription(symbol: "000", name: "0000000000000000", balance: 10000, marketUsd: 1)
            token.isSkeleton = true
            return token 
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
        var nfts: [NFTDescription]
        
        static func mock() -> [NFTsCollectionDescription] {
            let names = ["Azuki", "Mutant Ape Yacht Club", "DeGods", "Grunchy Tigers"]
            var collections = [NFTsCollectionDescription]()
            
            for name in names {
                let numOfNFTs = Int(arc4random_uniform(10) + 1)
                let nfts = (0...numOfNFTs).map { _ in  NFTDescription.mock() }
                let collection = NFTsCollectionDescription(collectionName: name, nfts: nfts)
                collections.append(collection)
            }
            
            return collections
        }
    }
    
    struct NFTDescription: Hashable, Identifiable {
        var id: String { mint ?? UUID().uuidString }
        
        let name: String?
        let description: String?
        let imageUrl: URL?
        let videoUrl: URL?
        let link: String?
        let tags: [String]
        let collection: String?
        let mint: String?
        var chain: NFTModelChain?
        var address: String?
        
        var icon: UIImage?
        
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
            self.imageUrl = URL(string: nftModel.imageUrl ?? "")
            self.videoUrl = URL(string: nftModel.videoUrl ?? "")
            self.link = nftModel.link
            self.tags = nftModel.tags
            self.collection = nftModel.collection
            self.mint = nftModel.mint
            self.chain = nftModel.chain
            self.address = nftModel.address
        }

        init(name: String? = nil, description: String? = nil, imageUrl: URL? = nil, videoUrl: URL? = nil, link: String? = nil, tags: [String], collection: String? = nil, mint: String? = nil, chain: NFTModelChain? = nil, address: String? = nil) {
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
            .init(name: "Name", 
                  imageUrl: URL(string: "https://google.com"),
                  tags: [], mint: UUID().uuidString)
        }
        
        func loadIcon() async -> UIImage? {
            guard let imageUrl else { return nil }
            
//            try? await Task.sleep(seconds: TimeInterval(arc4random_uniform(5)))
//            return UIImage.Preview.previewLandscape
            return await appContext.imageLoadingService.loadImage(from: .url(imageUrl, maxSize: nil),
                                                                  downsampleDescription: .mid)
        }
    }
}
