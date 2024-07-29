//
//  TestableWalletConnectServiceV2.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import Foundation
@testable import domains_manager_ios

final class TestableWalletConnectServiceV2: WalletConnectServiceV2Protocol {
    func sendSignTx(sessions: [domains_manager_ios.WCConnectedAppsStorageV2.SessionProxy], chainId: Int, tx: domains_manager_ios.EthereumTransaction, address: domains_manager_ios.HexAddress, in wallet: domains_manager_ios.UDWallet) async throws -> domains_manager_ios.ResponseV2 {
        throw TestableGenericError.generic
    }
    
    var delegate: (any WalletConnectDelegate)?
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectURI {
        throw TestableGenericError.generic
    }
    
    func setUIHandler(_ uiHandler: any WalletConnectUIConfirmationHandler) {
        
    }
    
    func setWalletUIHandler(_ walletUiHandler: any WalletConnectClientUIHandler) {
        
    }
    
    func getConnectedApps() -> [UnifiedConnectAppInfo] {
        []
    }
    
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws {
        
    }
    
    func disconnectAppsForAbsentWallets(from: [WalletEntity]) {
        
    }
    
    func findSessions(by walletAddress: HexAddress) -> [WCConnectedAppsStorageV2.SessionProxy] {
        []
    }
    
    func clearCache() {
        
    }
    
    func connect(to wcWallet: WCWalletsProvider.WalletRecord) async throws -> WalletConnectServiceV2.Wc2ConnectionType {
        throw TestableGenericError.generic

    }
    
    func disconnect(from wcWallet: HexAddress) async {
        
    }
    
    func sendPersonalSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress, in wallet: UDWallet) async throws -> ResponseV2 {
        throw TestableGenericError.generic
    }
    
    func sendSignTypedData(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, dataString: String, address: HexAddress, in wallet: UDWallet) async throws -> ResponseV2 {
        throw TestableGenericError.generic

    }
    
    func sendEthSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress, in wallet: UDWallet) async throws -> ResponseV2 {
        throw TestableGenericError.generic

    }
    
    func handle(response: ResponseV2) throws -> String {
        throw TestableGenericError.generic
    }
    
    func signTxViaWalletConnect_V2(udWallet: UDWallet, sessions: [SessionV2Proxy], chainId: Int, tx: EthereumTransaction) async throws -> String {
        throw TestableGenericError.generic

    }
    
    func proceedSendTxViaWC_2(sessions: [SessionV2Proxy], chainId: Int, txParams: WCAnyCodable, in wallet: UDWallet) async throws -> ResponseV2 {
        throw TestableGenericError.generic

    }
    
    
}
