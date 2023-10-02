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
    static let ensDomainTLD: String = "eth"
    static let lensDomainTLD: String = "lens"
    static let coinbaseDomainTLD: String = "id"
    static let swiftUIPreviewDevices = ["iPhone 14 Pro", "iPhone 14 Pro Max", "iPhone SE (1st generation)", "iPhone SE (3rd generation)", "iPhone 13 mini"]
    static let defaultMessagingServiceIdentifier: MessagingServiceIdentifier = .xmtp
    
    
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
