//
//  Version.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 24.02.2021.
//

import Foundation

struct Version: Comparable, Codable {
    let major: Int
    let minor: Int
    let revision: Int
    
    private static func parse(version: String) -> Version? {
        let components = version.split(separator: Character.dotSeparator)
        guard components.count == 3 else { return nil }
        guard let major = Int(components[0]) else { return nil }
        guard let minor = Int(components[1]) else { return nil }
        guard let revision = Int(components[2]) else { return nil }
        return Version(major: major, minor: minor, revision: revision)
    }
    
    static func parse(versionString: String) throws -> Version {
        guard let version = parse(version: versionString) else {
            Debugger.printFailure("Failed to parse app version", critical: true)
            throw Self.Error.failedToParseFromString
        }

        return version
    }
    
    static func < (lhs: Version, rhs: Version) -> Bool {
        guard lhs.major == rhs.major else { return lhs.major < rhs.major }
        guard lhs.minor == rhs.minor else { return lhs.minor < rhs.minor }
        return lhs.revision < rhs.revision
    }
    
    static func getCurrentAppVersionString() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    static func getCurrentAppVersionStringThrowing() throws -> String {
        guard let appVersionString = getCurrentAppVersionString() else {
            Debugger.printFailure("Failed to get app version from bundle", critical: true)
            throw Self.Error.failedToGetVersionFromBundle
        }
        
        return appVersionString
    }
    
    static func getCurrent() throws -> Version {
        let currentVersionString = try getCurrentAppVersionStringThrowing()
        let currentVersion = try parse(versionString: currentVersionString)
        
        return currentVersion
    }
    
    enum Error: String, LocalizedError {
        case failedToGetVersionFromBundle
        case failedToParseFromString
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

enum AppVersionApiError: String, Error, RawValueLocalizable {
    case invalidDataFromServer
}

protocol AppVersionApi {
    func fetchVersion() async throws -> AppVersionInfo
}

struct AppVersionAPIResponse: Decodable {
    struct IOS: Decodable {
        let minSupportedVersion: String
        let supportedStoreLink: String
    }

    let ios: IOS
    let claimingIsEnabled: Bool
    let polygonClaimingReleased: Bool
    let mintingZilTldOnPolygonReleased: Bool
    let tlds: [String]
    var dotcoinDeprecationReleased: Bool?
    var mobileUnsReleaseVersion: String?
    var limits: AppConfigurationLimits?
}

struct AppConfigurationLimits: Codable {
    let maxWalletAddressesRequestLimit: Int
}

struct AppVersionInfo: Codable {
    var minSupportedVersion: Version = Version(major: 4, minor: 6, revision: 6)
    var supportedStoreLink: String = "https://apps.apple.com/us/app/unstoppable-domains-app/id\(Constants.appStoreAppId)"
    var mintingIsEnabled: Bool = true
    var polygonMintingReleased: Bool = true
    var mintingZilTldOnPolygonReleased: Bool = false
    var dotcoinDeprecationReleased: Bool?
    var mobileUnsReleaseVersion: String?
    var tlds: [String] = ["x",
                         "crypto",
                         "coin",
                         "wallet",
                         "bitcoin",
                         "888",
                         "nft",
                         "dao",
                         "zil"]
    var limits: AppConfigurationLimits?
}

struct DefaultAppVersionFetcher: AppVersionApi {
    
    func fetchVersion() async throws -> AppVersionInfo {
        let request = APIRequestBuilder().version().build()
        let data = try await NetworkService().fetchData(for: request.url,
                                                        method: .get,
                                                        extraHeaders: NetworkConfig.stagingAccessKeyIfNecessary)
        
        if let response = AppVersionAPIResponse.objectFromData(data),
           let minSupportedVersion = try? Version.parse(versionString: response.ios.minSupportedVersion) {
            let appVersion = AppVersionInfo(minSupportedVersion: minSupportedVersion,
                                            supportedStoreLink: response.ios.supportedStoreLink,
                                            mintingIsEnabled: response.claimingIsEnabled,
                                            polygonMintingReleased: response.polygonClaimingReleased,
                                            mintingZilTldOnPolygonReleased: response.mintingZilTldOnPolygonReleased,
                                            dotcoinDeprecationReleased: response.dotcoinDeprecationReleased,
                                            mobileUnsReleaseVersion: response.mobileUnsReleaseVersion,
                                            tlds: response.tlds,
                                            limits: response.limits)
            return appVersion
        } else {
            throw AppVersionApiError.invalidDataFromServer
        }
    }
    
}
