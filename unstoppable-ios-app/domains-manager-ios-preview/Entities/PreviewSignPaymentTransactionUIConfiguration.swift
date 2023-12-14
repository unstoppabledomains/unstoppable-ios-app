//
//  PreviewSignPaymentTransactionUIConfiguration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

struct SignPaymentTransactionUIConfiguration {
    struct TxDisplayDetails {
        let quantity: Int
        let gasPrice: Int
        let gasLimit: Int
        let description: String
        
        var gasFee: Int {
            gasPrice * gasLimit
        }
        
        init?(tx: EthereumTransaction) {
            guard let quantity = tx.value?.quantity,
                  let gasPrice = tx.gasPrice?.quantity,
                  let gasLimit = tx.gas?.quantity else { return nil }
            
            
            self.quantity = quantity
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
            self.description = tx.description
        }
    }
    
    
    let connectionConfig: WalletConnectServiceV2.ConnectionConfig
    let walletAddress: HexAddress
    let chainId: Int
    let cost: TxDisplayDetails
    
    var isGasFeeOnlyTransaction: Bool {
        cost.quantity == 0
    }
}

struct EthereumTransaction {
    var value: Value?
    var gasPrice: Value?
    var gas: Value?
    
    var description: String { "" }
    
    struct Value {
        let quantity: Int
    }
}
