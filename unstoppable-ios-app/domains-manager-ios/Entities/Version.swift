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
    
    static func parse(version: String) -> Version? {
        let components = version.split(separator: Character.dotSeparator)
        guard components.count == 3 else { return nil }
        guard let major = Int(components[0]) else { return nil }
        guard let minor = Int(components[1]) else { return nil }
        guard let revision = Int(components[2]) else { return nil }
        return Version(major: major, minor: minor, revision: revision)
    }
    
    static func < (lhs: Version, rhs: Version) -> Bool {
        guard lhs.major == rhs.major else { return lhs.major < rhs.major }
        guard lhs.minor == rhs.minor else { return lhs.minor < rhs.minor }
        return lhs.revision < rhs.revision
    }
    
    static func getAppVersion() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
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
}

struct AppVersionInfo: Codable {
    var minSupportedVersion: Version = Version(major: 0, minor: 3, revision: 1)
    var supportedStoreLink: String = "https://apps.apple.com/us/app/unstoppable-domains-app/id1544748602"
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
}

struct DefaultAppVersionFetcher: AppVersionApi {
    
    func fetchVersion() async throws -> AppVersionInfo {
        let request = APIRequestBuilder().version().build()
        let data = try await NetworkService().fetchData(for: request.url,
                                                        method: .get,
                                                        extraHeaders: NetworkConfig.stagingAccessKeyIfNecessary)
        
        if let response = AppVersionAPIResponse.objectFromData(data),
           let minSupportedVersion = Version.parse(version: response.ios.minSupportedVersion) {
            let appVersion = AppVersionInfo(minSupportedVersion: minSupportedVersion,
                                            supportedStoreLink: response.ios.supportedStoreLink,
                                            mintingIsEnabled: response.claimingIsEnabled,
                                            polygonMintingReleased: response.polygonClaimingReleased,
                                            mintingZilTldOnPolygonReleased: response.mintingZilTldOnPolygonReleased,
                                            dotcoinDeprecationReleased: response.dotcoinDeprecationReleased,
                                            mobileUnsReleaseVersion: response.mobileUnsReleaseVersion,
                                            tlds: response.tlds)
            return appVersion
        } else {
            throw AppVersionApiError.invalidDataFromServer
        }
    }
    
}
