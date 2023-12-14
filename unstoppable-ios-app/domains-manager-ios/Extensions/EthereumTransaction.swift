//
//  EthereumTransaction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation
import Boilertalk_Web3

extension EthereumTransaction {
    var description: String {
        return """
        to: \(to == nil ? "" : String(describing: to!.hex(eip55: true))),
        value: \(value == nil ? "" : String(describing: value!.hex())),
        gasPrice: \(gasPrice == nil ? "" : String(describing: gasPrice!.hex())),
        gas: \(gas == nil ? "" : String(describing: gas!.hex())),
        data: \(data.hex()),
        nonce: \(nonce == nil ? "" : String(describing: nonce!.hex()))
        """
    }
}
