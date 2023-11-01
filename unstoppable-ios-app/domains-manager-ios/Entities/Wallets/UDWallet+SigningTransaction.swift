//
//  UDWallet+SigningTransaction.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 22.02.2023.
//

import Foundation
import Boilertalk_Web3
import WalletConnectSwift

extension UDWallet {
    func getTxSignature(ethTx: EthereumTransaction, chainId: Int, request: Request) async throws -> String {
        guard self.walletState == .verified else {
            return try await signTransactionViaWalletConnect(ethTx: ethTx, request: request, chainId: chainId)
        }
        
        let signature = try signTxLocally_V1(ethTx: ethTx, chainId: BigUInt(chainId))
        return signature
    }
    
    func signTransactionViaWalletConnect(ethTx: EthereumTransaction,
                                         request: Request,
                                         chainId: Int) async throws -> String {
        let sessions_V2 = appContext.walletConnectServiceV2.findSessions(by: address)
        if sessions_V2.count > 0 {
            return try await appContext.walletConnectServiceV2.signTxViaWalletConnect_V2(udWallet: self,
                                                                                         sessions: sessions_V2,
                                                                                         chainId: chainId,
                                                                                         tx: ethTx)
        }
        
        throw WalletConnectRequestError.noWCSessionFound
    }
    
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
