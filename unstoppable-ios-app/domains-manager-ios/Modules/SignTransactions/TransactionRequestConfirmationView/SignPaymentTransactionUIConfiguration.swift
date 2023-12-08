//
//  SignPaymentTransactionUIConfiguration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation
import Boilertalk_Web3

struct SignPaymentTransactionUIConfiguration {
    struct TxDisplayDetails {
        let quantity: BigUInt
        let gasPrice: BigUInt
        let gasLimit: BigUInt
        let description: String
        
        var gasFee: BigUInt {
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
