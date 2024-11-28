//
//  UDFeatureFlag.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.10.2023.
//

import Foundation

enum UDFeatureFlag: String, CaseIterable {
    case communityMediaEnabled = "ecommerce-service-users-enable-chat-community-media"
    case isBuyCryptoEnabled = "mobile-buy-crypto-enabled"
    case isSendCryptoEnabled = "mobile-send-crypto-enabled"
    case isBuyDomainEnabled = "mobile-buy-domain-enabled"
    
    case isMPCWalletEnabled = "mobile-mpc-wallet-enabled"
    case isMPCSendCryptoEnabled = "mobile-mpc-send-crypto-enabled"
    case isMPCMessagingEnabled = "mobile-mpc-messaging-enabled"
    case isMPCWCNativeEnabled = "mobile-mpc-wc-native-enabled"
    case isMPCSignatureEnabled = "mobile-mpc-signature-enabled"
    case isMPCPurchaseEnabled = "mobile-mpc-purchase-enabled"
    case isMPCMFAEnabled = "mobile-mpc-mfa-enabled"
    
    case isMaintenanceFullEnabled = "mobile-maintenance-full"
    case isMaintenanceOKLinkEnabled = "mobile-maintenance-oklink"
    case isMaintenanceProfilesAPIEnabled = "mobile-maintenance-profiles-api"
    case isMaintenanceEcommEnabled = "mobile-maintenance-ecomm"
    case isMaintenanceInfuraEnabled = "mobile-maintenance-infura"
    case isMaintenanceMPCEnabled = "mobile-maintenance-mpc"
    
    var defaultValue: Bool {
        switch self {
        case .communityMediaEnabled, .isBuyCryptoEnabled, .isMPCMessagingEnabled, .isMPCWCNativeEnabled, .isMaintenanceFullEnabled, .isMaintenanceOKLinkEnabled, .isMaintenanceProfilesAPIEnabled, .isMaintenanceEcommEnabled, .isMaintenanceInfuraEnabled, .isMaintenanceMPCEnabled, .isMPCMFAEnabled:
            return false
        case .isSendCryptoEnabled, .isMPCWalletEnabled, .isMPCSendCryptoEnabled, .isMPCSignatureEnabled, .isMPCPurchaseEnabled, .isBuyDomainEnabled:
            return true
        }
    }
    
    /// This flag has JSON structure 
    var isStructuredFlag: Bool {
        switch self {
        case .isMaintenanceFullEnabled, .isMaintenanceOKLinkEnabled, .isMaintenanceProfilesAPIEnabled, .isMaintenanceEcommEnabled, .isMaintenanceInfuraEnabled, .isMaintenanceMPCEnabled:
            return true
        case .isSendCryptoEnabled, .isMPCWalletEnabled, .isMPCSendCryptoEnabled, .isMPCSignatureEnabled, .isMPCPurchaseEnabled, .communityMediaEnabled, .isBuyCryptoEnabled, .isMPCMessagingEnabled, .isMPCWCNativeEnabled, .isBuyDomainEnabled, .isMPCMFAEnabled:
            return false
        }
    }
}
