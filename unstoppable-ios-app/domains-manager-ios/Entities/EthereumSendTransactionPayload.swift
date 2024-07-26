//
//  EthereumSendTransactionPayload.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.07.2024.
//

import Foundation

struct EthereumSendTransactionPayload  {
    let chainId: Int
    let transaction: EthereumTransaction
}
