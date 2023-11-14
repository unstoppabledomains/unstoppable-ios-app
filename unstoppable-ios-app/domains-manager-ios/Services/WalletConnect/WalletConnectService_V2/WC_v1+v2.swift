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


struct WCRegistryWalletProxy {
    let host: String
    let name: String
    
    // TODO: Remove when Ledger fixes the url in wallet info
    var needsLedgerSearchHack: Bool {
        name.lowercased().contains("ledger")
    }
    
    init?(_ walletInfo: SessionV2) {
        guard let url = URL(string: walletInfo.peer.url),
              let host = url.host else { return nil }
        self.host = host
        self.name = walletInfo.peer.name
    }
}

extension UDWallet {
    func sendTxViaWalletConnect(request: WalletConnectSign.Request,
                                chainId: Int) async throws -> JSONRPC.RPCResult {
        func sendSingleTx(tx: EthereumTransaction) async throws -> JSONRPC.RPCResult {
            let wc2Sessions = try getWC2Session()
            let response: WalletConnectSign.Response = try await appContext.walletConnectServiceV2.proceedSendTxViaWC_2(sessions: wc2Sessions,
                                                                                                                        chainId: chainId,
                                                                                                                        txParams: request.params,
                                                                                                                        in: self)
            let respCodable = AnyCodable(response)
            return .response(respCodable)
        }
        
        guard let transactionToSign = try? request.params.getTransactions().first else {
            throw WalletConnectRequestError.failedBuildParams
        }
        
        let response = try await sendSingleTx(tx: transactionToSign)
        return response
    }
    
}
