//
//  FirebaseAuthTokenStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.11.2023.
//

import Foundation
import Valet

protocol FirebaseAuthRefreshTokenStorageProtocol {
    func getAuthRefreshToken() -> String?
    func setAuthRefreshToken(_ token: String)
    func clearAuthRefreshToken()
}

struct ParkedDomainsFirebaseAuthTokenStorage: PrivateKeyStorage, FirebaseAuthRefreshTokenStorageProtocol {
    
    let valet: ValetProtocol
    static let keychainName = "unstoppable-parked-domains-fb-token"
    private let passwordKey = "com.unstoppable.parked.fb.token.key"
    private let userDefaultsKey: String = "firebaseRefreshToken"
    
    init() {
        valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                            accessibility: .whenUnlockedThisDeviceOnly)
        
        // Migrate from UserDefaults storage
        if let cachedToken = UserDefaults.standard.value(forKey: userDefaultsKey) as? String {
            setAuthRefreshToken(cachedToken)
            UserDefaults.standard.setValue(nil, forKey: userDefaultsKey)
        }
    }
        
    func getAuthRefreshToken() -> String? {
        retrieveValue(for: passwordKey, isCritical: false)
    }
    
    func setAuthRefreshToken(_ token: String) {
        try? valet.setString(token, forKey: passwordKey)
    }
    
    func clearAuthRefreshToken() {
        clear(forKey: passwordKey)
    }
}

struct PurchaseDomainsFirebaseAuthTokenStorage: PrivateKeyStorage, FirebaseAuthRefreshTokenStorageProtocol {
    
    let valet: ValetProtocol
    static let keychainName = "unstoppable-purchase-domains-fb-token"
    private let passwordKey = "com.unstoppable.purchase.fb.token.key"
    
    init() {
        valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                            accessibility: .whenUnlockedThisDeviceOnly)
    }
    
    func getAuthRefreshToken() -> String? {
        retrieveValue(for: passwordKey, isCritical: false)
    }
    
    func setAuthRefreshToken(_ token: String) {
        try? valet.setString(token, forKey: passwordKey)
    }
    
    func clearAuthRefreshToken() {
        clear(forKey: passwordKey)
    }
}
