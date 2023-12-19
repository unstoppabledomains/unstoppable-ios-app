//
//  Extension-String-Common.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.08.2023.
//

import Foundation
import web3swift

/// This extension shared with NotificationServiceExtension
typealias HexAddress = String

extension HexAddress {
  
    func ethChecksumAddress() -> String {
        EthereumAddress.toChecksumAddress(self) ?? self
    }
    
}
