//
//  PreviewString.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation
typealias HexAddress = String

extension HexAddress {
    static var hexPrefix: String { "0x" }
    
    var hasHexPrefix: Bool {
        return self.hasPrefix(String.hexPrefix)
    }
    
    var normalized: String {
        let cleanAddress = self.droppedHexPrefix.lowercased()
        if cleanAddress.count == 64 {
            return String.hexPrefix + cleanAddress.dropFirst(24)
        }
        return String.hexPrefix + cleanAddress
    }
    
    var droppedHexPrefix: String {
        return self.hasHexPrefix ? String(self.dropFirst(String.hexPrefix.count)) : self
    }
    
    func ethChecksumAddress() -> String {
        self
    }
    
    func isUDTLD() -> Bool {
        true
    }
}
extension String {
    
    /// Converts a hex string into an array of bytes
    ///
    /// - Returns: Array of 8 bit bytes
    func hexToBytes() -> [UInt8] {
        var value = self
        if self.count % 2 > 0 {
            value = "0" + value
        }
        let bytesCount = value.count / 2
        return (0..<bytesCount).compactMap({ i in
            let offset = i * 2
            if let str = value.substr(offset, 2) {
                return UInt8(str, radix: 16)
            }
            return nil
        })
    }
    
    /// Conveniently create a substring to more easily match JavaScript APIs
    ///
    /// - Parameters:
    ///   - offset: Starting index fo substring
    ///   - length: Length of desired substring
    /// - Returns: String representing the substring if passed indexes are in bounds
    func substr(_ offset: Int,  _ length: Int) -> String? {
        guard offset + length <= self.count else { return nil }
        let start = index(startIndex, offsetBy: offset)
        let end = index(start, offsetBy: length)
        return String(self[start..<end])
    }
}
