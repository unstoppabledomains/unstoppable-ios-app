//
//  FirebaseNetworkConfig.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import Foundation

struct FirebaseNetworkConfig {
 
    static var APIKey: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return FirebaseKeys.StagingAPIKey
        } else {
            return FirebaseKeys.ProductionAPIKey
        }
    }

    static var clientId: String {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        if isTestnetUsed {
            return FirebaseKeys.StagingClientId
        } else {
            return FirebaseKeys.ProductionClientId
        }
    }
    
    static var reversedClientId: String { clientId.components(separatedBy: ".").reversed().joined(separator: ".") }

    
}
