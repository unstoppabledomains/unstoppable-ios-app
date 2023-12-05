//
//  PreviewWCRequestsHandlingService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

protocol WCRequestsHandlingServiceProtocol {
    func addListener(_ listener: WalletConnectServiceConnectionListener)
    func removeListener(_ listener: WalletConnectServiceConnectionListener)
}

final class WCRequestsHandlingService: WCRequestsHandlingServiceProtocol, WalletConnectExternalWalletHandlerProtocol {
    func addListener(_ listener: WalletConnectServiceConnectionListener) { }
    func removeListener(_ listener: WalletConnectServiceConnectionListener) { }
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
    
    init(name: String = "Uniswap",
              walletAddress: String = "",
              domainName: String = "oleg.x") {
        self.walletAddress = walletAddress
        self.appName = name
        self.displayName = name
        self.domain = .init(name: domainName)
    }
    
}
