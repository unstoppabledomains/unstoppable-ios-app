//
//  WC_v1+v2.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 10.04.2023.
//

import Foundation
import Web3

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
        enum ClientInfo {
            case version1 (WalletConnectSwift.Session)
            case version2 (ClientDataV2)
        }
        
        let dAppInfoInternal: ClientInfo
        let isTrusted: Bool
        var iconURL: String?
        
        func getDappName() -> String {
            switch dAppInfoInternal {
            case .version1(let info): return info.dAppInfo.getDappName()
            case .version2(let data): return data.appMetaData.name
            }
        }
        
        func getDappHostName() -> String {
            switch dAppInfoInternal {
            case .version1(let info): return info.dAppInfo.getDappHostName()
            case .version2(let data): return data.appMetaData.url
            }
        }
        
        func getChainIds() -> [Int] {
            switch dAppInfoInternal {
            case .version1(let info):
                return [info.walletInfo?.chainId].compactMap({$0})
            case .version2(let info):
                guard let namespace = info.proposalNamespace[WalletConnectServiceV2.supportedNamespace] else {
                    return []
                }
                guard let chains = namespace.chains else { return [] }
                return chains.map {$0.reference}
                                        .compactMap({Int($0)})
            }
        }
        
        func getIconURL() -> URL? {
            switch dAppInfoInternal {
            case .version1(let info): return info.dAppInfo.getIconURL()
            case .version2(let info): return info.appMetaData.getIconURL()
            }
        }
        
        func getDappHostDisplayName() -> String {
            switch dAppInfoInternal {
            case .version1(let info): return info.dAppInfo.getDappHostDisplayName()
            case .version2(let info): return info.appMetaData.name
            }
        }
        
        func getPeerId() -> String? {
            switch dAppInfoInternal {
            case .version1(let info): return info.dAppInfo.peerId
            case .version2(let info): return nil
            }
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
    
    init?(_ walletInfo: WalletConnectSwift.Session.WalletInfo?) {
        guard let info = walletInfo else { return nil }
        guard let host = info.peerMeta.url.host else { return nil }
        self.host = host
    }
    
    init?(_ walletInfo: SessionV2) {
        guard let url = URL(string: walletInfo.peer.url),
              let host = url.host else { return nil }
        self.host = host
    }
}

extension UDWallet {
    func sendTxViaWalletConnect(request: WalletConnectSign.Request,
                                chainId: Int) async throws -> JSONRPC.RPCResult {
        func sendSingleTx(tx: EthereumTransaction) async throws -> JSONRPC.RPCResult {
            let session = try detectWCSessionType()
            switch session {
            case .wc1(let wc1Session):
                
                let response: WalletConnectSwift.Response = try await appContext.walletConnectExternalWalletHandler.sendTxViaWalletConnect_V1(session: wc1Session, tx: tx, in: self)
                let result = try response.result(as: String.self)
                
                print(result)
                let respCodable = AnyCodable(result)
                return .response(respCodable)
                
            case .wc2(let wc2Sessions):
                let response: WalletConnectSign.Response = try await appContext.walletConnectServiceV2.proceedSendTxViaWC_2(sessions: wc2Sessions,
                                                                                                                            chainId: chainId,
                                                                                                                            txParams: request.params,
                                                                                                                            in: self)
                let respCodable = AnyCodable(response)
                print(response)
                return .response(respCodable)
            }
        }
        
        guard let transactionToSign = try? request.params.getTransactions().first else {
            throw WalletConnectRequestError.failedBuildParams
        }
        
        let response = try await sendSingleTx(tx: transactionToSign)
        return response
    }
    
}
