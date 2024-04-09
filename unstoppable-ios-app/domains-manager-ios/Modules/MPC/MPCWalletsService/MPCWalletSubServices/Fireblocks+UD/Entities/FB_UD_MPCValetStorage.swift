//
//  FB_UD_MPCValetStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation
import Valet

extension FB_UD_MPC {
    final class ValetStorage: ValetProtocol {
        
        private let valet: ValetProtocol
        
        static let keychainName = "unstoppable-fb-mpc-storage"
        
        init() {
            valet = Valet.valet(with: Identifier(nonEmpty: Self.keychainName)!,
                                accessibility: .whenUnlockedThisDeviceOnly)
        }
        
        func setObject(_ object: Data, forKey key: String) throws {
            try valet.setObject(object, forKey: key)
        }
        
        func object(forKey key: String) throws -> Data {
            try valet.object(forKey: key)
        }
        
        func setString(_ privateKey: String, forKey: String) throws {
            try valet.setString(privateKey, forKey: forKey)
        }
        
        func string(forKey pubKeyHex: String) throws -> String {
            try valet.string(forKey: pubKeyHex)
        }
        
        func removeObject(forKey: String) throws {
            try valet.removeObject(forKey: forKey)
        }
        
    }
}
