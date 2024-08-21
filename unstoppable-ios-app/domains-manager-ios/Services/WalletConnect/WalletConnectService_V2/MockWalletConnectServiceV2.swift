//
//  MockWalletConnectServiceV2.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.11.2023.
//

import Foundation
import WalletConnectUtils
import WalletConnectSign
import Boilertalk_Web3

final class MockWalletConnectServiceV2 {
    var delegate: WalletConnectDelegate?
    
    private var connectedWallets = [UDWallet]()
    
    func saveWallet(_ wallet: UDWallet) {
        connectedWallets.append(wallet)
    }
}

// MARK: - WalletConnectServiceProtocol
extension MockWalletConnectServiceV2: WalletConnectServiceV2Protocol {
    func sendSignTx(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, tx: EthereumTransaction, address: HexAddress, in wallet: UDWallet) async throws -> ResponseV2 {
        throw WalletConnectRequestError.failedToSignMessage
    }
    
    func sendSignTypedData(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, dataString: String, address: HexAddress, in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.failedToSignMessage
    }
    
    func proceedSendTxViaWC_2(sessions: [SessionV2Proxy], chainId: Int, txParams: Commons.AnyCodable, in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.noWCSessionFound
    }
    
    func signTxViaWalletConnect_V2(udWallet: UDWallet, sessions: [SessionV2Proxy], chainId: Int, tx: EthereumTransaction) async throws -> String {
        return ""
    }
    
    func setWalletUIHandler(_ walletUiHandler: WalletConnectClientUIHandler) {
        
    }
    
    func sendPersonalSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress, in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.failedToSignMessage
    }
    
    func sendEthSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress, in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.failedToSignMessage
    }
    
    func handle(response: WalletConnectSign.Response) throws -> String {
        return "response"
    }
    
    func findSessions(by walletAddress: HexAddress) -> [WCConnectedAppsStorageV2.SessionProxy] {
        if let _ = connectedWallets.first(where: { $0.address == walletAddress }) {
            return  []
        }
        return []
    }
    
    func clearCache() {
        
    }
    
    func disconnectAppsForAbsentWallets(from: [WalletEntity]) {
    }
    
    func getConnectedApps() -> [UnifiedConnectAppInfo] {
        []
    }
    
    func disconnect(app: any UnifiedConnectAppInfoProtocol) {
        
    }
    
    func getConnectedApps() -> [WCConnectedAppsStorageV2.ConnectedApp] {
        []
    }
    
    func setUIHandler(_ uiHandler: WalletConnectUIConfirmationHandler) {
        
    }
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectUtils.WalletConnectURI {
        return WalletConnectUtils.WalletConnectURI(string: "fake")!
    }
    
    func pairClientAsync(uri: WalletConnectUtils.WalletConnectURI) {
        
    }
    
    func connect(to wcWallet: WCWalletsProvider.WalletRecord) async throws -> WalletConnectServiceV2.Wc2ConnectionType {
        return .oldPairing
    }
    
    func disconnect(from wcWallet: HexAddress) {
    }
}

// MARK: - Private methods
private extension WCConnectedAppsStorageV2.SessionProxy {
    init(topic: String, pairingTopic: String, peer: AppMetadata,
         namespaces: [String: SessionNamespace], expiryDate: Date) {
        self.topic = topic
        self.pairingTopic = pairingTopic
        self.peer = peer
        self.namespaces = namespaces
        self.expiryDate = expiryDate
    }
}
