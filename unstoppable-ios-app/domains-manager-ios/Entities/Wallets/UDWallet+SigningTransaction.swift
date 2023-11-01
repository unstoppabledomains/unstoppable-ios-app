//
//  UDWallet+SigningTransaction.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 22.02.2023.
//

import Foundation
import Boilertalk_Web3

extension UDWallet {
    func signTxLocally_V1(ethTx: EthereumTransaction, chainId: BigUInt) throws -> String {
        guard let privKeyString = self.getPrivateKey() else {
            Debugger.printFailure("No private key in \(self)", critical: true)
            throw WalletConnectRequestError.failedToGetPrivateKey
        }
        
        let privateKey = try EthereumPrivateKey(hexPrivateKey: privKeyString)
        
        let chainId = EthereumQuantity(quantity: chainId)
        let signedTx = try ethTx.sign(with: privateKey, chainId: chainId)
        let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
        let signature = r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)
        return signature
    }
}
