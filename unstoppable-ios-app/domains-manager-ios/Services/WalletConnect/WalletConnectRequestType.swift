//
//  WalletConnectRequestType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.02.2023.
//

import Foundation

enum WalletConnectRequestType: String, CaseIterable, Hashable {
    case personalSign = "personal_sign"
    case ethSign = "eth_sign"
    case ethSignTransaction = "eth_signTransaction"
    case ethGetTransactionCount = "eth_getTransactionCount"
    case ethSendTransaction = "eth_sendTransaction"
    case ethSendRawTransaction = "eth_sendRawTransaction"
    case ethSignedTypedData = "eth_signTypedData"
    
    var string: String { self.rawValue }
    
}
