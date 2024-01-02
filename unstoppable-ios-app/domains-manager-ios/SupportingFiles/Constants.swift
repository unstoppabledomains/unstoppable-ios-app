//
//  Constants.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 19.10.2020.
//

import Foundation
import UIKit

typealias EmptyCallback = ()->()
typealias EmptyAsyncCallback = @Sendable ()->()
typealias MainActorCallback = @MainActor ()->()
typealias MainActorAsyncCallback = @Sendable @MainActor ()->()
typealias GlobalConstants = Constants

struct Constants {
    
    #if DEBUG
    static let updateInterval: TimeInterval = 30
    #else
    static let updateInterval: TimeInterval = 60
    #endif
        
    static let distanceFromButtonToKeyboard: CGFloat = 16
    static let scrollableContentBottomOffset: CGFloat = 32
    static let ETHRegexPattern = "^0x[a-fA-F0-9]{40}$"
    static let UnstoppableSupportMail = "support@unstoppabledomains.com"
    static let UnstoppableTwitterName = "unstoppableweb"
    static let UnstoppableGroupIdentifier = "group.unstoppabledomains.manager.extensions"

    static let defaultWalletsNumberLimit = 25
    static let nonRemovableDomainCoins = ["ETH", "MATIC"]
    static let domainNameMinimumScaleFactor: CGFloat = 0.625
    static let maximumConcurrentNetworkRequestsLimit = 3
    static let backEndThrottleErrorCode = 429
    static let setupRRPromptRepeatInterval = 7
    static var wcConnectionTimeout: TimeInterval = 5
    static var newNonInteractableTLDs: Set<String> = []
    static var deprecatedTLDs: Set<String> = []
    static let imageProfileMaxSize: Int = 4_000_000 // 4 MB
    static let standardWebHosts = ["https://", "http://"]
    static let downloadedImageMaxSize: CGFloat = 512
    static let downloadedIconMaxSize: CGFloat = 128
    static let defaultUNSReleaseVersion = "v0.7.6"
    static let defaultInitials: String = "N/A"
    static let appStoreAppId = "1544748602"
    static let refreshDomainBadgesInterval: TimeInterval = 60 * 3 // 3 min
    static let parkingBetaLaunchDate = Date(timeIntervalSince1970: 1678401000)
    static let numberOfUnreadMessagesBeforePrefetch: Int = 7
    static let maxImageResolution: CGFloat = 1000
    static let shouldHideBlockedUsersLocally = true
    static let isCommunitiesEnabled = false
    static let ensDomainTLD: String = "eth"
    static let comDomainTLD: String = "com"
    static let lensDomainTLD: String = "lens"
    static let coinbaseDomainTLD: String = "id"
    static let swiftUIPreviewDevices = ["iPhone 14 Pro", "iPhone 14 Pro Max", "iPhone SE (1st generation)", "iPhone SE (3rd generation)", "iPhone 13 mini"]
    static let defaultMessagingServiceIdentifier: MessagingServiceIdentifier = .xmtp
    static let udMeHosts: Set<String> = ["ud.me", "staging.ud.me"]
    static let popularCoinsTickers: [String] = ["BTC", "ETH", "ZIL", "LTC", "XRP"] // This is not required order to be on the UI

    
    // Shake to find
    static let shakeToFindServiceId: String = "090DAE5A-0DD8-4327-B074-E1E09B259597"
    static let shakeToFindCharacteristicId: String = "3403C4D9-2C2C-4A6A-A9DB-115D10095771"

#if DEBUG
    static let isTestingMinting: Bool = false
    static let testMintingDomainsCount = 10
    #else
    static let isTestingMinting: Bool = false
    static let testMintingDomainsCount = 0
    #endif

    static let UDContractAddresses: Set<String> = Set([
        /// UNSRegistry
        "0x049aba7510f45BA5b64ea9E658E342F904DB358D",
        "0x049aba7510f45BA5b64ea9E658E342F904DB358D",
        "0x070e83FCed225184E67c86302493ffFCDB953f71",
        "0x070e83FCed225184E67c86302493ffFCDB953f71",
        "0xa9a6A3626993D487d2Dbda3173cf58cA1a9D9e9f",
        "0xa9a6A3626993D487d2Dbda3173cf58cA1a9D9e9f",
        "0x2a93C52E7B6E7054870758e15A1446E769EdfB93",
        "0x2a93C52E7B6E7054870758e15A1446E769EdfB93",
        
        /// ProxyReader
        "0x58034A288D2E56B661c9056A0C27273E5460B63c",
        "0xE3b961856C417d081a02cBa0161a051268F52677",
        "0x423F2531bd5d3C3D4EF7C318c2D1d9BEDE67c680",
        "0x6fe7c857C1B0E54492C8762f27e0a45CA7ff264B",
        
        "0xfEe4D4F0aDFF8D84c12170306507554bC7045878",
        "0xa6E7cEf2EDDEA66352Fd68E5915b60BDbb7309f5",
        "0x7ea9Ee21077F84339eDa9C80048ec6db678642B1",
        "0xFc5f608149f4D9e2Ed0733efFe9DD57ee24BCF68",
        
        /// ProxyAdmin
        "0xAA16DA78110D9A9742c760a1a064F28654Ab93de",
        "0xf4906E210523F9dA79E33811A44EE000441F4E04",
        "0xe1D668052D52388F52b90f4d1798DB2b04bC3b88",
        "0x460d63117c7Ab1624b7474C45BF46eC6702f57ce",
        
        /// Resolver
        "0xb66DcE2DA6afAAa98F2013446dBCB0f4B0ab2842",
        "0xc33aBEe943be2A2DA50708bAb61F47d581ee450d",
        "0x0555344A5F440Bd1d8cb6B42db46c5e5D4070437",
        "0xFCc1A95B7287Ae7a8B7cA813F12991dF5714d4C7",
        
        /// Free minter
        "0x1fC985cAc641ED5846b631f96F35d9b48Bc3b834",
        
        ///MintableERC721Predicate
        "0x932532aA4c0174b8453839A6E44eE09Cc615F2b7",
        "0x56E14C4C1748a818a5564D33cF774c59EB3eDF59",
        
        ///RootChainManager
        "0xA0c68C638235ee32657e8f720a23ceC1bFc77C77",
        "0xBbD7cBFA79faee899Eaf900F13C9065bF03B1A74",
        
        ///MintingManager
        "0x2a7084870bB724175a3C96Da8FaA55128fa3E19D",
        "0xb970fbCF52cd8111c76c379D4f2FE12E7f8AE7fb",
        "0x9ee42D3EB042e06F8Cd241890C4fA0d51e4DA345",
        "0x7F9F48cF94C69ce91D4b442DA186F31118ac0185",
        "0x7be83293BeeDc9Eba1bd76c66A65F10F3efaeC26",
        "0xC37d3c4326ab0E1D2b9D8b916bBdf5715f780fcF",
        "0x428189346bb3CC52f031A1092fd47C919AC30A9f",
        "0xEf3a491A8750BEC2Dff5339CF6Df94436d432C4d",
        
        ///SignatureController
        "0x82EF94294C95aD0930055f31e53A34509227c5f7",
        "0x5199dAE4B24B987ba18FcE1b64664D1B798d372B",
        
        ///MintingController
        "0xb0EE56339C3253361730F50c08d3d7817ecD60Ca",
        "0xCEC41677be322049cC885c0DAe2fE0D52CA195ca",
        
        ///WhitelistedMinter
        "0xd3fF3377b0ceade1303dAF9Db04068ef8a650757",
        
        ///URIPrefixController
        "0x09B091492759737C03da9dB7eDF1CD6BCC3A9d91",
        "0x29465e3d2daA588E62375977bCe9b3f51406a794",
        
        ///DomainZoneController
        "0xeA70777e28E00E81f58b8921fC47F78B8a72eFE7",
    ].map { $0.lowercased() })
    
    
}
 
let currencyNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3
    formatter.numberStyle = .decimal
    return formatter
}()

let largeNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
}()

let bytesFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    return formatter
}()

struct Env {
    static let IOS = "ios"
    
    static let schemeDescription : String = {
        #if DEBUG
            return "Debug"
        #else
            return "Release"
        #endif
        // Intentionally let builds fail that are not explicitly described here
    }()
}

enum BlockchainNetwork: Int, CaseIterable {
    case ethMainnet = 1
    case ethRinkby = 4
    case ethGoerli = 5
    case polygonMainnet = 137
    case polygonMumbai = 80001
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .ethMainnet:
            return "mainnet"
        case .ethRinkby:
            return "rinkby"
        case .ethGoerli:
            return "goerli"
        case .polygonMainnet:
            return "polygon-mainnet"
        case .polygonMumbai:
            return "polygon-mumbai"
        }
    }
    
    var nameForClient: String {
        switch self {
        case .ethMainnet:
            return "Ethereum"
        case .ethRinkby:
            return "Ethereum: Rinkby"
        case .ethGoerli:
            return "Ethereum: Goerli"
        case .polygonMainnet:
            return "Polygon"
        case .polygonMumbai:
            return "Polygon: Mumbai"
        }
    }
}

struct Utilities {
    static func catchingFailureAsyncTask<T>(asyncCatching block: () async throws -> T, defaultValue: T) async -> T {
        do {
            return try await block()
        } catch {
            return defaultValue
        }
    }
}
