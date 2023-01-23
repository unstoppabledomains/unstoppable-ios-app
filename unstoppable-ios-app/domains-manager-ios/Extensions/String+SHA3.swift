//
//  String+SHA3.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.09.2022.
//

import Foundation

extension String {
    var hashSha3Value: Int? {
        guard let data = self.data(using: .utf8) else { return nil }
        let hash = data.sha3(.keccak256).toHexString()
        guard let int64 = UInt64(hash.prefix(16), radix:16) else {
            return nil
        }
        return Int(truncatingIfNeeded: int64)
    }
    
    var hashSha3String: String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.sha3(.keccak256).toHexString()
    }
    
    var walletBackUpPasswordHash: String? { hashSha3String }
}
