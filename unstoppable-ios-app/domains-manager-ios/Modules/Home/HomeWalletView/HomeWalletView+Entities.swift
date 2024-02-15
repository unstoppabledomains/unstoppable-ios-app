//
//  HomeWalletView+Entities.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

protocol HomeViewSortingOption: Hashable, CaseIterable {
    var title: String { get }
    var analyticName: String { get }
}

protocol HomeWalletActionItem: Identifiable, Hashable {
    associatedtype SubAction: HomeWalletSubActionItem
    
    var title: String { get }
    var icon: Image { get }
    var isDimmed: Bool { get }
    var analyticButton: Analytics.Button { get }
    var subActions: [SubAction] { get }
}


protocol HomeWalletSubActionItem: RawRepresentable, CaseIterable, Hashable where RawValue == String {
    var title: String { get }
    var icon: Image { get }
    var isDestructive: Bool { get }
    var analyticButton: Analytics.Button { get }
}

extension HomeWalletSubActionItem {
    var isDestructive: Bool { false }
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
    
    
    enum WalletAction: HomeWalletActionItem {
        
        var id: String {
            switch self {
            case .buy:
                return "buy"
            case .receive:
                return "receive"
            case .profile(let enabled):
                return "profile_\(enabled)"
            case .more:
                return "more"
            }
        }
        
        case buy
        case receive
        case profile(enabled: Bool)
        case more
        
        var title: String {
            switch self {
            case .receive:
                return String.Constants.receive.localized()
            case .profile:
                return String.Constants.profile.localized()
            case .buy:
                return String.Constants.buy.localized()
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
            case .buy:
                return .creditCard2Icon
            case .more:
                return .dotsIcon
            }
        }
        
        var subActions: [WalletSubAction] {
            switch self {
            case .receive, .profile, .buy:
                return []
            case .more:
                return WalletSubAction.allCases
            }
        }
        
        var analyticButton: Analytics.Button {
            switch self {
            case .buy:
                return .buy
            case .receive:
                return .receive
            case .profile:
                return .profile
            case .more:
                return .more
            }
        }
        
        var isDimmed: Bool {
            switch self {
            case .buy, .receive, .more:
                return false
            case .profile(let enabled):
                return !enabled
            }
        }
    }
    
    enum WalletSubAction: String, CaseIterable, HomeWalletSubActionItem {
        
        case copyWalletAddress
        case connectedApps
        
        var title: String {
            switch self {
            case .copyWalletAddress:
                return String.Constants.copyWalletAddress.localized()
            case .connectedApps:
                return String.Constants.connectedAppsTitle.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .copyWalletAddress:
                return Image.systemDocOnDoc
            case .connectedApps:
                return Image.systemAppBadgeCheckmark
            }
        }
        
        var analyticButton: Analytics.Button {
            switch self {
            case .copyWalletAddress:
                return .copyWalletAddress
            case .connectedApps:
                return .connectedApps
            }
        }
    }
    
    enum TokensSortingOptions: String, Hashable, CaseIterable, HomeViewSortingOption {
        
        case highestValue, marketValue, alphabetical
        
        var title: String {
            switch self {
            case .highestValue:
                return String.Constants.sortHighestValue.localized()
            case .marketValue:
                return String.Constants.sortMarketValue.localized()
            case .alphabetical:
                return String.Constants.sortAlphabetical.localized()
            }
        }
        var analyticName: String { rawValue }
    }
    
    enum CollectiblesSortingOptions: String, Hashable, CaseIterable, HomeViewSortingOption {
        case mostRecent, mostCollected, alphabetical
        
        var title: String {
            switch self {
            case .mostRecent:
                return String.Constants.sortMostRecent.localized()
            case .mostCollected:
                return String.Constants.sortMostCollected.localized()
            case .alphabetical:
                return String.Constants.sortAlphabetical.localized()
            }
        }
        var analyticName: String { rawValue }
    }
    
    enum DomainsSortingOptions: String, Hashable, CaseIterable, HomeViewSortingOption {
        case alphabeticalAZ, alphabeticalZA
        
        var title: String {
            switch self {
            case .alphabeticalAZ:
                return String.Constants.sortAlphabeticalAZ.localized()
            case .alphabeticalZA:
                return String.Constants.sortAlphabeticalZA.localized()
            }
        }
        
        var analyticName: String { rawValue }
    }
}

extension HomeWalletView {
    struct TokenDescription: Hashable, Identifiable {
        var id: String { "\(chain)/\(symbol)" }
        
        let chain: String
        let symbol: String
        let name: String
        let balance: Double
        let balanceUsd: Double
        var marketUsd: Double?
        var marketPctChange24Hr: Double?
        var parentSymbol: String?
        var logoURL: URL?
        var parentLogoURL: URL?
        private(set) var isSkeleton: Bool = false
       
        static let iconSize: InitialsView.InitialsSize = .default
        static let iconStyle: InitialsView.Style = .gray
        
        init(walletBalance: WalletTokenPortfolio) {
            self.chain = walletBalance.symbol
            self.symbol = walletBalance.symbol
            self.name = walletBalance.name
            self.balance = walletBalance.balanceAmt.rounded(toDecimalPlaces: 2)
            self.balanceUsd = walletBalance.value.walletUsdAmt
            self.marketUsd = walletBalance.value.marketUsdAmt ?? 0
            self.marketPctChange24Hr = walletBalance.value.marketPctChange24Hr
        }
        
        init(chain: String, symbol: String, name: String, balance: Double, balanceUsd: Double, marketUsd: Double? = nil,
             marketPctChange24Hr: Double? = nil,
             icon: UIImage? = nil) {
            self.chain = chain
            self.symbol = symbol
            self.name = name
            self.balance = balance
            self.balanceUsd = balanceUsd
            self.marketUsd = marketUsd
            self.marketPctChange24Hr = marketPctChange24Hr
        }
        
        init(chain: String, walletToken: WalletTokenPortfolio.Token, parentSymbol: String, parentLogoURL: URL?) {
            self.chain = chain
            self.symbol = walletToken.symbol
            self.name = walletToken.name
            self.balance = walletToken.balanceAmt.rounded(toDecimalPlaces: 2)
            self.balanceUsd = walletToken.value?.walletUsdAmt ?? 0
            self.marketUsd = walletToken.value?.marketUsdAmt ?? 0
            self.marketPctChange24Hr = walletToken.value?.marketPctChange24Hr
            self.parentSymbol = parentSymbol
            self.logoURL = URL(string: walletToken.logoUrl ?? "")
        }
        
        static func extractFrom(walletBalance: WalletTokenPortfolio) -> [TokenDescription] {
            let tokenDescription = TokenDescription(walletBalance: walletBalance)
            let parentSymbol = walletBalance.symbol
            let parentLogoURL = URL(string: walletBalance.logoUrl ?? "")
            let chainSymbol = walletBalance.symbol
            let subTokenDescriptions = walletBalance.tokens?.map({ TokenDescription(chain: chainSymbol,
                                                                                    walletToken: $0,
                                                                                    parentSymbol: parentSymbol,
                                                                                    parentLogoURL: parentLogoURL) })
                                                            .filter({ $0.balanceUsd >= 1 }) ?? []
            
            return [tokenDescription] + subTokenDescriptions
        }
        
        static func createSkeletonEntity() -> TokenDescription {
            var token = TokenDescription(chain: "ETH", symbol: "000", name: "0000000000000000", balance: 10000, balanceUsd: 10000, marketUsd: 1)
            token.isSkeleton = true
            return token 
        }
        
        func loadTokenIcon(iconUpdated: @escaping (UIImage?)->()) {
            TokenDescription.loadIconFor(ticker: symbol, logoURL: logoURL, iconUpdated: iconUpdated)
        }
        
        func loadParentIcon(iconUpdated: @escaping (UIImage?)->()) {
            if let parentSymbol {
                TokenDescription.loadIconFor(ticker: parentSymbol, logoURL: parentLogoURL, iconUpdated: iconUpdated)
            } else {
                iconUpdated(nil)
            }
        }
        
        static func loadIconFor(ticker: String, logoURL: URL?, iconUpdated: @escaping (UIImage?)->()) {
            if let logoURL,
               let cachedImage = appContext.imageLoadingService.cachedImage(for: .url(logoURL, maxSize: nil), downsampleDescription: .icon) {
                iconUpdated(cachedImage)
                return
            }
            
            let size = TokenDescription.iconSize
            let style = TokenDescription.iconStyle
            if let cachedImage = appContext.imageLoadingService.cachedImage(for: .currencyTicker(ticker,
                                                                                                 size: size,
                                                                                                 style: style),
                                                                            downsampleDescription: .icon) {
                iconUpdated(cachedImage)
                return
            }
            Task { @MainActor in
                let initials = await appContext.imageLoadingService.loadImage(from: .initials(ticker,
                                                                                              size: size,
                                                                                              style: style),
                                                                              downsampleDescription: nil)
                iconUpdated(initials)
                
                if let logoURL,
                   let icon = await appContext.imageLoadingService.loadImage(from: .url(logoURL,
                                                                                        maxSize: nil),
                                                                             downsampleDescription: .icon) {
                    iconUpdated(icon)
                } else if let icon = await appContext.imageLoadingService.loadImage(from: .currencyTicker(ticker,
                                                                                                   size: size,
                                                                                                   style: style),
                                                                             downsampleDescription: .icon) {
                    iconUpdated(icon)
                }
            }
        }
    }
}

extension HomeWalletView {
    struct NFTsCollectionDescription: Hashable, Identifiable {
        var id: String { collectionName }

        let collectionName: String
        let nfts: [NFTDisplayInfo]
        let numberOfNFTs: Int
        let chainSymbol: String
        let nftsNativeValue: Double
        let nftsUsdValue: Double
        let lastSaleDate: Date?
        
        init(collectionName: String, nfts: [NFTDisplayInfo]) {
            self.collectionName = collectionName
            self.nfts = nfts
            self.numberOfNFTs = nfts.count 
            chainSymbol = nfts.first?.chain?.rawValue ?? ""
            let saleDetails = nfts.compactMap({ $0.lastSaleDetails })
            nftsNativeValue = saleDetails.reduce(0.0, { $0 + $1.valueNative })
            nftsUsdValue = saleDetails.reduce(0.0, { $0 + $1.valueUsd })
            lastSaleDate = saleDetails.sorted(by: { $0.date > $1.date }).first?.date
        }
    }
    
}

extension HomeWalletView {
    struct NotMatchedRecordsDescription: Hashable, Identifiable {
        var id: String { chain.rawValue }
        
        let chain: BlockchainType
        let numberOfRecordsNotSetToChain: Int
        let ownerWallet: String
    }
}


extension HomeWalletView {
    struct DomainsGroup: Hashable, Identifiable {
        var id: String { tld }
        
        let domains: [DomainDisplayInfo]
        let tld: String
        let numberOfDomains: Int
        
        init(domains: [DomainDisplayInfo], tld: String) {
            self.domains = domains.sorted(by: { lhs, rhs in
                lhs.name < rhs.name
            })
            self.tld = tld
            numberOfDomains = domains.count
        }
    }
}
