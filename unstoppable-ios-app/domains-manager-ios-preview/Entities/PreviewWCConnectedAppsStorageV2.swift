//
//  PreviewWCConnectedAppsStorageV2.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

struct WCConnectedAppsStorageV2 {
    
    static let shared = WCConnectedAppsStorageV2()
    
    private init() { }
    
    
    struct SessionProxy: Codable, Hashable {
//        public let topic: String
//        public let pairingTopic: String
//        public let peer: AppMetadata
        var namespaces: [String: SessionNamespace] = [:]
//        public let expiryDate: Date
        
        init(_ session: SessionV2) {
//            self.topic = session.topic
//            self.pairingTopic = session.pairingTopic
//            self.peer = session.peer
//            self.namespaces = session.namespaces
//            self.expiryDate = session.expiryDate
        }
        
        func getWalletAddresses() -> [HexAddress] {
            Array(namespaces.values).map({ Array($0.accounts)
                .map({$0.address}) })
            .flatMap({ $0 })
            .map({ $0.normalized })
        }
    }
    
    struct ConnectedApp: Codable, Equatable, Hashable, CustomStringConvertible {
     
        var walletAddress: HexAddress
        var appName: String
        
        var description: String {
            "ConnectedApp:"
        }
        
    }
}

struct AppMetadata {
    
}

struct SessionNamespace: Hashable, Codable {
    var accounts: Set<Account>

    struct Account: Hashable, Codable {
        var address: String = ""
    }
}
