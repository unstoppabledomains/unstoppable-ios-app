//
//  PreviewWCRequestsHandlingService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation
import Combine

final class WCRequestsHandlingService: WCRequestsHandlingServiceProtocol, WalletConnectExternalWalletHandlerProtocol {
    private(set) var eventsPublisher = PassthroughSubject<WalletConnectServiceEvent, Never>()

    func handleWCRequest(_ request: WCRequest, target: UDWallet) async throws {
        
    }
    func setUIHandler(_ uiHandler: WalletConnectUIErrorHandler) { }
    func addListener(_ listener: WalletConnectServiceConnectionListener) { }
    func removeListener(_ listener: WalletConnectServiceConnectionListener) { }
    func expectConnection() { }
}

protocol WalletConnectExternalWalletHandlerProtocol {
    
    
}

struct UnifiedConnectAppInfo: UnifiedConnectAppInfoProtocol {
    
    
    var walletAddress: HexAddress
    var appName: String
    var displayName: String { appName }
    
    var appIconUrls: [String] = []
    var appUrlString: String = ""
    var description: String = ""
    var appInfo: WalletConnectServiceV2.WCServiceAppInfo = .init()
    var connectionStartDate: Date? = Date()
    var chainIds: [Int] = []

    init(name: String = "Uniswap",
         walletAddress: String = "") {
        self.walletAddress = walletAddress
        self.appName = name
    }
    
    init(from appV2: WCConnectedAppsStorageV2.ConnectedApp) {
        self.walletAddress = appV2.walletAddress
        self.appName = appV2.appName
    }
    
}
