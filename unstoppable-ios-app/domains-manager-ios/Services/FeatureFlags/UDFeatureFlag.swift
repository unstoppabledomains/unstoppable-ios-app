//
//  UDFeatureFlag.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.10.2023.
//

import Foundation

enum UDFeatureFlag: String, CaseIterable {
    case communityMediaEnabled = "ecommerce-service-users-enable-chat-community-media"
    case udBlueRequiredForCommunities = "ecommerce-service-users-enable-chat-community-udBlue"
    
    var defaultValue: Bool {
        switch self {
        case .communityMediaEnabled, .udBlueRequiredForCommunities:
            return false
        }
    }
}
