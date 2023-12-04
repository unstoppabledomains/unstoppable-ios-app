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
    
    var appIconUrls: [String]
    
    var appName: String
    
    var appUrlString: String
    
    var displayName: String
    
    var description: String
    
    var appInfo: WalletConnectServiceV2.WCServiceAppInfo
    
    var connectionStartDate: Date?
    
    let domain: DomainItem

}
