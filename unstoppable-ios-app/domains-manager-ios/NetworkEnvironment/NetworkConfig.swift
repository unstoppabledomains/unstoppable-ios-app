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
            return "api.ud-staging.com"
        } else {
            return "api.unstoppabledomains.com"
        }
    }
    
    static var migratedBaseUrl: String {
        "https://\(Self.migratedEndpoint)"
    }
    
    static var websiteHost: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return "www.ud-staging.com"
        } else {
            return "unstoppabledomains.com"
        }
    }
    static var websiteBaseUrl: String {
        "https://\(Self.websiteHost)"
    }
    
    static var buyCryptoUrl: String {
        websiteBaseUrl + "/fiat-ramps?utm_source=ud_ios url"
    }
    
    static var baseDomainProfileUrl: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return "https://staging.ud.me/"
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
        baseAPIUrl + "/resolve"
    }
    
    static var baseAPIHost: String {
        if User.instance.getSettings().isTestnetUsed {
            return "api.ud-staging.com"
        } else {
            return "api.unstoppabledomains.com"
        }
    }
    
    static var baseAPIUrl: String {
        "https://\(baseAPIHost)"
    }
    
    private static let StagingAccessApiKey = "mob-01-stg-8792ed66-f0d6-463d-b08b-7f5667980676"
    static var stagingAccessKeyIfNecessary: [String : String] {
        if User.instance.getSettings().isTestnetUsed {
            return ["X-Proxy-ApiKey" : StagingAccessApiKey]
        } else {
            return [:]
        }
    }
    
    static var disableFastlyCacheHeader: [String : String] {
        ["X-Fastly-Force-Refresh" : "true"]
    }

    static var currentEnvironment: UnsConfigManager.BlockchainEnvironment {
        if User.instance.getSettings().isTestnetUsed {
            return .testnet
        } else {
            return .mainnet
        }
    }
    
    private static let okLinkBaseURL = "https://www.oklink.com"
    
    static var basePolygonNetworkScanUrl: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return okLinkBaseURL + "/amoy"
        }
        return okLinkBaseURL + "/polygon"
    }
    
    static var baseEthereumNetworkScanUrl: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return okLinkBaseURL + "/sepolia-test"
        }
        return okLinkBaseURL + "/eth"
    }
    
    static func currencyIconUrl(for currency: CoinRecord) -> String {
        let url = "https://storage.googleapis.com/unstoppable-client-assets/images/icons/\(currency.ticker)/icon.svg"
        return url
    }
    
    static func currencyIconUrl(for ticker: String) -> String {
        let url = "https://storage.googleapis.com/unstoppable-client-assets/images/icons/\(ticker)/icon.svg"
        return url
    }

    static func nonNFTDomainImageUrl(for path: String) -> String {
        let url = "https://storage.googleapis.com/unstoppable-client-assets/\(path)"
        return url
    }
    
    private static var coinResolverHost: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return "api.ud-staging.com"
        } else {
            return "unstoppabledomains.com"
        }
    }
    
    static func coinsResolverURL(version: String) -> String {
        "https://" + coinResolverHost + "/uns_resolver_keys.json?tag=\(version)"
    }
    
    static func hotFeatureSuggestionsURL() -> String {
        "https://raw.githubusercontent.com/unstoppabledomains/unstoppable-ios-app/main/unstoppable-ios-app/domains-manager-ios/SupportingFiles/Data/hot-suggestions.json"
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
