//
//  WC_v1+v2.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 10.04.2023.
//

import Foundation
import Boilertalk_Web3


// V2
import WalletConnectUtils
import WalletConnectSign


extension UDWallet {
    func sendTxViaWalletConnect(request: WalletConnectSign.Request,
                                chainId: Int) async throws -> JSONRPC.RPCResult {
        func sendSingleTx(tx: EthereumTransaction) async throws -> JSONRPC.RPCResult {
            let wc2Sessions = try getWC2Session()
            let response: WalletConnectSign.Response = try await appContext.walletConnectServiceV2.proceedSendTxViaWC_2(sessions: wc2Sessions,
                                                                                                                        chainId: chainId,
                                                                                                                        txParams: request.params,
                                                                                                                        in: self)
            let respCodable = WCAnyCodable(response)
            return .response(respCodable)
        }
        
        guard let transactionToSign = try? request.params.getTransactions().first else {
            throw WalletConnectRequestError.failedBuildParams
        }
        
        let response = try await sendSingleTx(tx: transactionToSign)
        return response
    }
    
}
