//
//  DefaultAppVersionFetcher.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

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
                                            tldsToPurchase: response.tldsToPurchase,
                                            dnsTlds: response.dnsTlds,
                                            limits: response.limits)
            return appVersion
        } else {
            throw AppVersionApiError.invalidDataFromServer
        }
    }
    
}
