//
//  PreviewKeychainPrivateKeyStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

struct KeychainPrivateKeyStorage: PrivateKeyStorage {
    let valet: ValetProtocol
    static let keychainName = "unstoppable-keychain"
    private init() {
        valet = PreviewValet()
    }
    
    static var instance = KeychainPrivateKeyStorage()
    
    static func retrievePasscode() -> String? {
        nil
    }
}
