//
//  DeepLinks.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.12.2021.
//

import Foundation

enum DeepLinkOperation: String, Codable {
    
    case importWallets = "MobileImportWallets"
    case mintDomains = "MobileMintDomains"
    
    init?(_ string: String) {
        switch string {
        case Self.importWallets.rawValue: self = .importWallets
        case Self.mintDomains.rawValue: self = .mintDomains
        default: return nil
        }
    }
}

struct DeepLinkDetailsStorage {
    // saving
    static func save(email: String) {
        save(string: email, key: .accountEmailKey)
    }
    
    static func save(code: String?) {
        save(string: code, key: .securityCodeKey)
    }
    
    static func save(action: String) {
        save(string: action, key: .actionKey)
    }
    
    static func save(string: String?, key: Key) {
        UserDefaults.standard.set(string == nil ? nil : string!, forKey: key.rawValue)
    }
    
    static func retrieveEmailWithCleaning() -> String? {
        retrieveWithCleaning(key: .accountEmailKey)
    }
    
    static func retrieveCodeWithCleaning() -> String? {
        retrieveWithCleaning(key: .securityCodeKey)
    }
    
    static func retrieveActionWithCleaning() -> String? {
        retrieveWithCleaning(key: .actionKey)
    }
    
    static func retrieveWithCleaning(key: Key) -> String? {
        let result = retrieve(key: key)
        clean(key: key)
        return result
    }
    
    static func retrieve(key: Key) -> String? {
        UserDefaults.standard.object(forKey: key.rawValue) as? String
    }
    
    static func clean(key: Key)  {
        UserDefaults.standard.set(nil, forKey: key.rawValue)
    }
}

extension DeepLinkDetailsStorage {
    enum Key: String {
        case accountEmailKey = "EMAIL_TO_CLAIM_DOMAINS"
        case securityCodeKey = "SECURITY_CODE"
        case actionKey = "DEEP_LINK_ACTION"
    }
}
