//
//  KeychainPrivateKeyStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2023.
//

import Foundation
import Valet

struct KeychainPrivateKeyStorage: PrivateKeyStorage {
    let valet: ValetProtocol
    static let keychainName = "unstoppable-keychain"
    private init() {
        valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                            accessibility: .whenUnlockedThisDeviceOnly)
    }
    
    static var instance = KeychainPrivateKeyStorage()
    
    static func retrievePasscode() -> String? {
        Self.instance.retrieveValue(for: .passcode, isCritical: false)
    }
}
