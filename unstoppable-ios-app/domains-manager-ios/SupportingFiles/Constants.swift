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
 
struct Constants {
    
    #if DEBUG
    static let updateInterval: TimeInterval = 30
    #else
    static let updateInterval: TimeInterval = 60
    #endif
        
    static let distanceFromButtonToKeyboard: CGFloat = 16
    static var biometricUIProcessingTime: TimeInterval { appContext.authentificationService.biometricType == .touchID ? 0.5 : 1.2 }
    static let scrollableContentBottomOffset: CGFloat = 32
    static let ETHRegexPattern = "^0x[a-fA-F0-9]{40}$"
    static let UnstoppableSupportMail = "support@unstoppabledomains.com"
    static let UnstoppableTwitterName = "unstoppableweb"

    static let nonRemovableDomainCoins = ["ETH", "MATIC"]
    static let domainNameMinimumScaleFactor: CGFloat = 0.625
    static let maximumConcurrentNetworkRequestsLimit = 3
    static let backEndThrottleErrorCode = 429
    static let setupRRPromptRepeatInterval = 7
    static var wcConnectionTimeout: TimeInterval = 5
    static let wcNoResponseFromExternalWalletTimeout: TimeInterval = 0.5
    static var deprecatedTLDs: Set<String> = []
    static let imageProfileMaxSize: Int = 4_000_000 // 4 MB
    static let standardWebHosts = ["https://", "http://"]
    static let downloadedImageMaxSize: CGFloat = 512
    static let downloadedIconMaxSize: CGFloat = 128
    static let defaultUNSReleaseVersion = "v0.6.19"
    static let defaultInitials: String = "N/A"
    static let appStoreAppId = "1544748602"
    static let refreshDomainBadgesInterval: TimeInterval = 60 * 3 // 3 min
    static let parkingBetaLaunchDate = Date(timeIntervalSince1970: 1678401000)
    
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

var appContext: AppContextProtocol {
    return AppDelegate.shared.appContext
}
