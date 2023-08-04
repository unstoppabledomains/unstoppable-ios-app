//
//  Extension-String-Common.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.08.2023.
//

import Foundation

/// This extension shared with NotificationServiceExtension
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
}
