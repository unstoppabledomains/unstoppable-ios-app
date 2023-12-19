//
//  WalletConnectServiceV2Protocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

protocol WalletConnectServiceV2Protocol: AnyObject {
    var delegate: WalletConnectDelegate? { get set }
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectURI
    func setUIHandler(_ uiHandler: WalletConnectUIConfirmationHandler)
    func setWalletUIHandler(_ walletUiHandler: WalletConnectClientUIHandler)
    func getConnectedApps() async -> [UnifiedConnectAppInfo]
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws
    func disconnectAppsForAbsentDomains(from: [DomainItem])
    
    func findSessions(by walletAddress: HexAddress) -> [WCConnectedAppsStorageV2.SessionProxy]
    
    // Client V2 part
    func connect(to wcWallet: WCWalletsProvider.WalletRecord) async throws -> WalletConnectServiceV2.Wc2ConnectionType
    func disconnect(from wcWallet: HexAddress) async
    
    func sendPersonalSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress, in wallet: UDWallet) async throws -> ResponseV2
    func sendSignTypedData(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, dataString: String, address: HexAddress, in wallet: UDWallet) async throws -> ResponseV2
    func sendEthSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress,
                     in wallet: UDWallet) async throws -> ResponseV2
    func handle(response: ResponseV2) throws -> String
    func signTxViaWalletConnect_V2(udWallet: UDWallet,
                                   sessions: [SessionV2Proxy],
                                   chainId: Int,
                                   tx: EthereumTransaction) async throws -> String
    
    func proceedSendTxViaWC_2(sessions: [SessionV2Proxy],
                              chainId: Int,
                              txParams: AnyCodable,
                              in wallet: UDWallet) async throws -> ResponseV2
}


protocol WalletConnectDelegate: AnyObject {
    func failedToConnect()
    func didConnect(to walletAddress: HexAddress?, with wcRegistryWallet: WCRegistryWalletProxy?, successfullyAddedCallback: (()->Void)?)
    func didDisconnect(from accounts: [HexAddress]?, with wcRegistryWallet: WCRegistryWalletProxy?)
}
