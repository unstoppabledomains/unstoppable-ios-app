//
//  MetadataNetworkConfig.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2022.
//

import Foundation

struct MetadataNetworkConfig {
    static let stagingHost = "resolve.staging.unstoppabledomains.com"
    static let productionHost = "metadata.unstoppabledomains.com"
    
    static var baseUrl: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return "https://\(Self.stagingHost)"
        } else {
            return "https://\(Self.productionHost)"
        }
    }
    
    static var host: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return Self.stagingHost
        } else {
            return Self.productionHost
        }
    }
    
    static var authAPIKey: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return NetworkService.testnetMetadataAPIKey
        } else {
            return NetworkService.mainnetMetadataAPIKey
        }
    }
    
    static var authHeader: [String : String] {
        return ["Authorization" : "Bearer \(authAPIKey)"]
    }
}
