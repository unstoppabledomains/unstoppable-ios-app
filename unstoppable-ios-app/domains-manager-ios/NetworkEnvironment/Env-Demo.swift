//
//  GateConfiguration-Demo.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 11.03.2021.
//

import Foundation

// This is how the file GateConfiguration.swift is done:
// If you compile your code, please use your own project IDs

extension NetworkService {
    
    // Your Infura Project ID as an JRPC Provider
    static let mainnetInfuraProjectId = "<your_project_id>"
    static let rinkebyInfuraProjectId = "<your_project_id>"
    
    // Internal UD API
    static let mainnetMetadataAPIKey = "<mainnet-api-key>"
    static let testnetMetadataAPIKey = "<testnet-api-key>"
    
}

struct AppIdentificators {
    // WalletConnect2 Project Id
    static let wc2ProjectId = "<id>"
}

extension PaymentConfiguration {
    // Need to enter keys to enable Apple Pay via Stripe
    
    struct Merchant {
        static let identifier = "<merchant-id>"
    }
    
    struct Stripe {
        #if TESTFLIGHT
        static let defaultPublishableKey = "<stripe-test-key>"
        #else
        static let defaultPublishableKey = "<stripe-live-key>"
        #endif
        static let developmentKey = "<stripe-dev-key>"
    }
}

struct FirebaseKeys {
    static let ProductionAPIKey = "<firebase-prod-api-key>"  // 27.10.2023 new key ending in 'xMQY'
    static let StagingAPIKey = "<firebase-staging-api-key>"
    
    static let ProductionClientId = "<firebase-prod-client-id>"
    static let StagingClientId = "<firebase-staging-client-id>"
}

struct LaunchDarkly {
    static let stagingMobileKey = "<launch-darkly-staging-key>"
    static let productionMobileKey = "<launch-darkly-production-key>"
}
