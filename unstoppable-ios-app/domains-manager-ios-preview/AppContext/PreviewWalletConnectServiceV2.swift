//
//  PreviewWalletConnectServiceV2.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

typealias ResponseV2 = String
typealias SessionV2Proxy = String

final class WalletConnectServiceV2: WalletConnectServiceV2Protocol {
    var delegate: WalletConnectDelegate?
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectURI {
        throw NSError()
    }
    
    func setUIHandler(_ uiHandler: WalletConnectUIConfirmationHandler) {
        
    }
    
    func setWalletUIHandler(_ walletUiHandler: WalletConnectClientUIHandler) {
        
    }
    
    func disconnectAppsForAbsentWallets(from: [WalletEntity]) {
        
    }
    
    func findSessions(by walletAddress: HexAddress) -> [WCConnectedAppsStorageV2.SessionProxy] {
        []
    }
    
    func connect(to wcWallet: WCWalletsProvider.WalletRecord) async throws -> Wc2ConnectionType {
        throw NSError()
    }
    
    func disconnect(from wcWallet: HexAddress) async {
        
    }
    
    func sendPersonalSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress, in wallet: UDWallet) async throws -> ResponseV2 {
        throw NSError()
    }
    
    func sendSignTypedData(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, dataString: String, address: HexAddress, in wallet: UDWallet) async throws -> ResponseV2 {
        throw NSError()
    }
    
    func sendEthSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress, in wallet: UDWallet) async throws -> ResponseV2 {
        throw NSError()
    }
    
    func handle(response: ResponseV2) throws -> String {
        ""
    }
    
    func signTxViaWalletConnect_V2(udWallet: UDWallet, sessions: [SessionV2Proxy], chainId: Int, tx: EthereumTransaction) async throws -> String {
        ""
    }
    
    func proceedSendTxViaWC_2(sessions: [SessionV2Proxy], chainId: Int, txParams: AnyCodable, in wallet: UDWallet) async throws -> ResponseV2 {
        throw NSError()
    }
    
    
    static var connectedAppsToUse: [UnifiedConnectAppInfo] = [.init(name: "Foundation", walletAddress: "123")]
    
    func getConnectedApps() -> [UnifiedConnectAppInfo] {
        let wallets = MockEntitiesFabric.Wallet.mockEntities()
        
        let apps: [UnifiedConnectAppInfo] = [.init(name: "Foundation", walletAddress: wallets[0].address),
                                             .init(name: "OpenSea", walletAddress: wallets[0].address),
                                             .init(name: "LensFrens", walletAddress: wallets[1].address)]
        
        return apps
    }
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws {
        
    }
    struct WCServiceAppInfo: Hashable {
        var isTrusted: Bool { true }
        func getDisplayName() -> String {
            "Display name"
        }
        func getDappName() -> String {
            "Dapp name"
        }
        func getDappHostName() -> String {
            "Dapp host name"
        }
        func getChainIds() -> [Int] {
            [8001]
        }
        func getDappHostDisplayName() -> String {
            "Dapp host displayName"
        }
        func getIconURL() -> URL? {
            URL(string: "https://google.com")
        }
    }
}

protocol UnifiedConnectAppInfoProtocol: Equatable, Hashable, Sendable {
    var walletAddress: HexAddress { get }
    var appIconUrls: [String] { get }
    
    var appName: String { get }
    var appUrlString: String { get }
    var displayName: String { get }
    var description: String { get }
    var appInfo: WalletConnectServiceV2.WCServiceAppInfo { get }
    var connectionStartDate: Date? { get }
    var chainIds: [Int] { get }
}

public struct WalletConnectURI: Equatable {
    var topic: String
    var version: String
    var symKey: String
    var absoluteString: String
}
