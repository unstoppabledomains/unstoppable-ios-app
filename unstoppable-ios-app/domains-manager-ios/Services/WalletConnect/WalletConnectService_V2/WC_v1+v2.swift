//
//  WC_v1+v2.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 10.04.2023.
//

import Foundation
import Boilertalk_Web3

// V1
import WalletConnectSwift

// V2
import WalletConnectUtils
import WalletConnectSign
import WalletConnectEcho

extension WalletConnectService {
    enum ConnectWalletRequest: Equatable {
        case version1 (WCURL)
        case version2 (WalletConnectURI)
    }
}

extension WalletConnectService {
    struct ClientDataV2 {
        let appMetaData: WalletConnectSign.AppMetadata
        let proposalNamespace: [String: ProposalNamespace]
    }
    
    struct WCServiceAppInfo {
        
        let dAppInfoInternal: ClientDataV2
        let isTrusted: Bool
        var iconURL: String?
        
        func getDappName() -> String {
            return dAppInfoInternal.appMetaData.name
        }
        
        func getDappHostName() -> String {
            return dAppInfoInternal.appMetaData.url
        }
        
        func getChainIds() -> [Int] {
            guard let namespace = dAppInfoInternal.proposalNamespace[WalletConnectServiceV2.supportedNamespace] else {
                return []
            }
            guard let chains = namespace.chains else { return [] }
            return chains.map {$0.reference}
                                    .compactMap({Int($0)})
        }
        
        func getIconURL() -> URL? {
            return dAppInfoInternal.appMetaData.getIconURL()
        }
        
        func getDappHostDisplayName() -> String {
            dAppInfoInternal.appMetaData.name
        }
        
        func getPeerId() -> String? {
            return nil
        }
        
        func getDisplayName() -> String {
            let name = getDappName()
            if name.isEmpty {
                return getDappHostDisplayName()
            }
            return name
        }
    }
}

struct WCRegistryWalletProxy {
    let host: String
    let name: String
    
    // TODO: Remove when Ledger fixes the url in wallet info
    var needsLedgerSearchHack: Bool {
        name.lowercased().contains("ledger")
    }
    
    init?(_ walletInfo: WalletConnectSwift.Session.WalletInfo?) {
        guard let info = walletInfo else { return nil }
        guard let host = info.peerMeta.url.host else { return nil }
        self.host = host
        self.name = info.peerMeta.name
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
