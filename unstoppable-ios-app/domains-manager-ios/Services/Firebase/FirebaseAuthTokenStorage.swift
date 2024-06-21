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

class FirebaseAuthTokenStorage: PrivateKeyStorage, FirebaseAuthRefreshTokenStorageProtocol {
    let valet: ValetProtocol
    static let keychainName = "unstoppable-purchase-domains-fb-token"
    var passwordKey: String { "" }
    
    init() {
        valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                            accessibility: .whenUnlockedThisDeviceOnly)
        assert(passwordKey.isEmpty == false, "Password key should not be empty")
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

final class ParkedDomainsFirebaseAuthTokenStorage: FirebaseAuthTokenStorage {
        
    override var passwordKey: String { "com.unstoppable.parked.fb.token.key" }
    private let userDefaultsKey: String = "firebaseRefreshToken"
    
    override init() {
        super.init()
        
        // Migrate from UserDefaults storage
        if let cachedToken = UserDefaults.standard.value(forKey: userDefaultsKey) as? String {
            setAuthRefreshToken(cachedToken)
            UserDefaults.standard.setValue(nil, forKey: userDefaultsKey)
        }
    }
}

final class PurchaseDomainsFirebaseAuthTokenStorage: FirebaseAuthTokenStorage {
    
    override var passwordKey: String { "com.unstoppable.purchase.fb.token.key" }
    
}

final class PurchaseMPCWalletFirebaseAuthTokenStorage: FirebaseAuthTokenStorage {
    
    override var passwordKey: String { "com.unstoppable.purchase.mpc.fb.token.key" }
    
}

final class FirebaseAuthInMemoryStorage: FirebaseAuthRefreshTokenStorageProtocol {
    
    private var token: String? = nil
    
    func getAuthRefreshToken() -> String? {
        token
    }
    
    func setAuthRefreshToken(_ token: String) {
        self.token = token
    }
    
    func clearAuthRefreshToken() {
        token = nil
    }
}
