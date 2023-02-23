//
//  UDWallet+SigningTransaction.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 22.02.2023.
//

import Foundation
import Web3
import WalletConnectSwift
import PromiseKit

extension UDWallet {
    func getTxSignature(ethTx: EthereumTransaction, chainId: BigUInt, request: Request) async throws -> String {
        guard self.walletState == .verified else {
            return try await signTransactionViaWalletConnect(ethTx: ethTx, request: request)
        }
        
        let signature = try signTxLocally_V1(ethTx: ethTx, chainId: chainId)
        return signature
    }
    
    func signTransactionViaWalletConnect(ethTx: EthereumTransaction,
                                         request: Request) async throws -> String {
        if let session_V1 = appContext.walletConnectClientService.findSessions(by: address).first {
            
            return try await singTxViaWalletConnect_V1(sessionWithExtWallet: session_V1,
                                                       request: request,
                                                       tx: ethTx)
        }
        
        let sessions_V2 = appContext.walletConnectServiceV2.findSessions(by: address)
        if sessions_V2.count > 0 {
            return try await appContext.walletConnectServiceV2.signTxViaWalletConnect_V2(udWallet: self,
                                                                                         sessions: sessions_V2,
                                                                                         tx: ethTx)
        }
        
        throw WalletConnectService.Error.noWCSessionFound
    }
    
    private func singTxViaWalletConnect_V1(sessionWithExtWallet: Session,
                                           request: Request,
                                           tx: EthereumTransaction) async throws -> String {
        
        return try await withSafeCheckedThrowingContinuation { continuation in
            self.signTxViaWalletConnect(session: sessionWithExtWallet, tx: tx)
                .done { response in
                    if let error = response.error {
                        continuation(.failure(error))
                    }
                    let result = try response.result(as: String.self)
                    continuation(.success(result))
                }.catch { error in
                    continuation(.failure(error))
                }
        }
    }
    
    func signTxLocally_V1(ethTx: EthereumTransaction, chainId: BigUInt) throws -> String {
        guard let privKeyString = self.getPrivateKey() else {
            Debugger.printFailure("No private key in \(self)", critical: true)
            throw WalletConnectService.Error.failedToGetPrivateKey
        }
        
        let privateKey = try EthereumPrivateKey(hexPrivateKey: privKeyString)
        
        let chainId = EthereumQuantity(quantity: chainId)
        let signedTx = try ethTx.sign(with: privateKey, chainId: chainId)
        let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
        let signature = r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)
        return signature
    }
}
