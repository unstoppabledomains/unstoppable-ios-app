//
//  NetworkConfig.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 02.12.2020.
//

import Foundation

struct NetworkConfig {
    enum NetworkType: String, Codable {
        case mainnet
        case testnet
    }
    
    static var migratedEndpoint: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return "mobile-staging.api.ud-staging.com"
        } else {
            return "unstoppabledomains.com"
        }
    }
    
    static var migratedBaseUrl: String {
        "https://\(Self.migratedEndpoint)"
    }
    
    static var baseDomainProfileUrl: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return "https://ud-staging.com/d/"
        }
        return "https://ud.me/"
    }
    
    static var badgesLeaderboardUrl: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return "https://ud-staging.com/badge/leaderboard"
        }
        return "https://unstoppabledomains.com/badge/leaderboard"
    }
    
    static var baseResolveUrl: String {
        if User.instance.getSettings().isTestnetUsed {
            return "https://resolve.ud-staging.com"
        } else {
            return "https://resolve.unstoppabledomains.com"
        }
    }
    
    static var baseProfileHost: String {
        if User.instance.getSettings().isTestnetUsed {
            return "profile.ud-staging.com"
        } else {
            return "profile.unstoppabledomains.com"
        }
    }
    
    static var baseProfileAPIHost: String {
        if User.instance.getSettings().isTestnetUsed {
            return "api.ud-staging.com"
        } else {
            return "api.unstoppabledomains.com"
        }
    }
    
    static var baseProfileAPIUrl: String {
        "https://\(baseProfileAPIHost)"
    }
    
    private static let StagingAccessApiKey = "mob-01-stg-8792ed66-f0d6-463d-b08b-7f5667980676"
    static var stagingAccessKeyIfNecessary: [String : String] {
        if User.instance.getSettings().isTestnetUsed {
            return ["X-Proxy-ApiKey" : StagingAccessApiKey]
        } else {
            return [:]
        }
    }

    static var currentEnvironment: UnsConfigManager.BlockchainEnvironment {
        if User.instance.getSettings().isTestnetUsed {
            return .testnet
        } else {
            return .mainnet
        }
    }
    
    static var baseNetworkScanUrl: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return "https://mumbai.polygonscan.com"
        }
        return "https://polygonscan.com"
    }
    
    static func currencyIconUrl(for currency: CoinRecord) -> String {
        let url = "https://storage.googleapis.com/unstoppable-client-assets/images/icons/\(currency.ticker)/icon.svg"
        return url
    }

    static func nonNFTDomainImageUrl(for path: String) -> String {
        let url = "https://storage.googleapis.com/unstoppable-client-assets/\(path)"
        return url
    }
    
    static func coinsResolverURL(version: String) -> String {
        "https://" + migratedEndpoint + "/uns_resolver_keys.json?tag=\(version)"
    }
}


extension NetworkConfig {
    static var currentNetNames: (String, String) {
        getNetNames(env: NetworkConfig.currentEnvironment)
    }
    
    typealias NetNames = (l1: String, l2: String)
    static func getNetNames(env: UnsConfigManager.BlockchainEnvironment) -> NetNames {
        let networksConfig = env.getBlockchainConfigData()
        return NetNames(l1: networksConfig.l1.name, l2: networksConfig.l2.name)
    }
}
