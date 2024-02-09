//
//  PreviewWCRequestsHandlingService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

final class WCRequestsHandlingService: WCRequestsHandlingServiceProtocol, WalletConnectExternalWalletHandlerProtocol {
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
    var displayName: String
    let domain: DomainItem
    
    var appIconUrls: [String] = []
    var appUrlString: String = ""
    var description: String = ""
    var appInfo: WalletConnectServiceV2.WCServiceAppInfo = .init()
    var connectionStartDate: Date? = Date()
    var chainIds: [Int] = []

    init(name: String = "Uniswap",
              walletAddress: String = "",
              domainName: String = "oleg.x") {
        self.walletAddress = walletAddress
        self.appName = name
        self.displayName = name
        self.domain = .init(name: domainName)
    }
    
}
