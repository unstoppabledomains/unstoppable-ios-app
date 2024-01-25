//
//  HomeWalletView+Entities.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

protocol HomeViewSortingOption: Hashable, CaseIterable {
    var title: String { get }
}

extension HomeWalletView {
    enum ContentType: String, CaseIterable {
        case tokens, collectibles, domains
        
        var title: String {
            switch self {
            case .tokens:
                return String.Constants.tokens.localized()
            case .collectibles:
                return String.Constants.collectibles.localized()
            case .domains:
                return String.Constants.domains.localized()
            }
        }
    }
    
    enum WalletAction: String, CaseIterable {
        case receive, profile, copy, more
        
        var title: String {
            switch self {
            case .receive:
                return String.Constants.receive.localized()
            case .profile:
                return String.Constants.profile.localized()
            case .copy:
                return String.Constants.copy.localized()
            case .more:
                return String.Constants.more.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .receive:
                return .arrowBottom
            case .profile:
                return .personIcon
            case .copy:
                return .squareBehindSquareIcon
            case .more:
                return .dotsIcon
            }
        }
        
        var subActions: [WalletSubAction] {
            switch self {
            case .receive, .profile, .copy:
                return []
            case .more:
                return [.connectedApps]
            }
        }
    }
    enum WalletSubAction: String, CaseIterable {
        case connectedApps
        
        var title: String {
            switch self {
            case .connectedApps:
                return String.Constants.connectedAppsTitle.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .connectedApps:
                return Image(systemName: "app.badge.checkmark")
            }
        }
    }
    
    enum TokensSortingOptions: Hashable, CaseIterable, HomeViewSortingOption {
        case highestValue, marketCap, alphabetical
        
        var title: String {
            switch self {
            case .highestValue:
                return "Highest Value"
            case .marketCap:
                return "Market Cap"
            case .alphabetical:
                return "Alphabetical"
            }
        }
    }
    
    enum CollectiblesSortingOptions: Hashable, CaseIterable, HomeViewSortingOption {
        case mostCollected, alphabetical
        
        var title: String {
            switch self {
            case .mostCollected:
                return "Most collected"
            case .alphabetical:
                return "Alphabetical"
            }
        }
    }
    
    enum DomainsSortingOptions: Hashable, CaseIterable, HomeViewSortingOption {
        case salePrice, alphabetical
        
        var title: String {
            switch self {
            case .salePrice:
                return "Highest Sale Price"
            case .alphabetical:
                return "Alphabetical"
            }
        }
    }
}

extension HomeWalletView {
    struct TokenDescription: Hashable, Identifiable {
        var id: String { symbol }
        
        let symbol: String
        let name: String
        let balance: Double
        let balanceUsd: Double
        var marketUsd: Double?
        var parentSymbol: String?
        private(set) var isSkeleton: Bool = false
       
        static let iconSize: InitialsView.InitialsSize = .default
        static let iconStyle: InitialsView.Style = .gray
        
        init(walletBalance: WalletTokenPortfolio) {
            self.symbol = walletBalance.symbol
            self.name = walletBalance.name
            self.balance = walletBalance.balanceAmt.rounded(toDecimalPlaces: 2)
            self.balanceUsd = walletBalance.value.walletUsdAmt
            self.marketUsd = walletBalance.value.marketUsdAmt ?? 0
        }
        
        init(symbol: String, name: String, balance: Double, balanceUsd: Double, marketUsd: Double? = nil, icon: UIImage? = nil) {
            self.symbol = symbol
            self.name = name
            self.balance = balance
            self.balanceUsd = balanceUsd
            self.marketUsd = marketUsd
        }
        
        init(walletToken: WalletTokenPortfolio.Token, parentSymbol: String) {
            self.symbol = walletToken.symbol
            self.name = walletToken.name
            self.balance = walletToken.balanceAmt.rounded(toDecimalPlaces: 2)
            self.balanceUsd = walletToken.value?.walletUsdAmt ?? 0
            self.marketUsd = walletToken.value?.marketUsdAmt ?? 0
            self.parentSymbol = parentSymbol
        }
        
        static func extractFrom(walletBalance: WalletTokenPortfolio) -> [TokenDescription] {
            let tokenDescription = TokenDescription(walletBalance: walletBalance)
            let subTokenDescriptions = walletBalance.tokens?.map { TokenDescription(walletToken: $0, parentSymbol: walletBalance.symbol) } ?? []
            
            return [tokenDescription] + subTokenDescriptions
        }
        
        static func createSkeletonEntity() -> TokenDescription {
            var token = TokenDescription(symbol: "000", name: "0000000000000000", balance: 10000, balanceUsd: 10000, marketUsd: 1)
            token.isSkeleton = true
            return token 
        }
        
        func loadTokenIcon(iconUpdated: @escaping (UIImage?)->()) {
            loadIconFor(ticker: symbol, iconUpdated: iconUpdated)
        }
        
        func loadParentIcon(iconUpdated: @escaping (UIImage?)->()) {
            if let parentSymbol {
                loadIconFor(ticker: parentSymbol, iconUpdated: iconUpdated)
            } else {
                iconUpdated(nil)
            }
        }
        
        private func loadIconFor(ticker: String, iconUpdated: @escaping (UIImage?)->()) {
            Task {
                let size = TokenDescription.iconSize
                let style = TokenDescription.iconStyle
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
                                             balanceUsd: value,
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
        var nfts: [NFTDisplayInfo]
        
        static func mock() -> [NFTsCollectionDescription] {
            let names = ["Azuki", "Mutant Ape Yacht Club", "DeGods", "Grunchy Tigers"]
            var collections = [NFTsCollectionDescription]()
            
            for name in names {
                let numOfNFTs = Int(arc4random_uniform(10) + 1)
                let nfts = (0...numOfNFTs).map { _ in  NFTDisplayInfo.mock() }
                let collection = NFTsCollectionDescription(collectionName: name, nfts: nfts)
                collections.append(collection)
            }
            
            return collections
        }
    }
    
}
