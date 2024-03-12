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
    struct NFTsCollectionDescription: Hashable, Identifiable {
        var id: String { collectionName }

        let collectionName: String
        let nfts: [NFTDisplayInfo]
        let numberOfNFTs: Int
        let chainSymbol: String
        let nftsNativeValue: Double
        let nftsUsdValue: Double
        let lastSaleDate: Date?
        let lastAcquiredDate: Date?
                
        init(collectionName: String, nfts: [NFTDisplayInfo]) {
            self.collectionName = collectionName
            self.nfts = nfts
            self.numberOfNFTs = nfts.count 
            chainSymbol = nfts.first?.chain?.rawValue ?? ""
            let saleDetails = nfts.compactMap({ $0.lastSaleDetails })
            nftsNativeValue = saleDetails.reduce(0.0, { $0 + $1.valueNative })
            nftsUsdValue = saleDetails.reduce(0.0, { $0 + $1.valueUsd })
            lastSaleDate = saleDetails.sorted(by: { $0.date > $1.date }).first?.date
            
            lastAcquiredDate = nfts.lazy.compactMap({ $0.acquiredDate }).sorted(by: { $0 > $1 }).first
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
