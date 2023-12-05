//
//  PreviewWalletConnectServiceV2.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

protocol WalletConnectServiceV2Protocol {
    func getConnectedApps() async -> [UnifiedConnectAppInfo]
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws
}


final class WalletConnectServiceV2: WalletConnectServiceV2Protocol {
    
    static var connectedAppsToUse: [UnifiedConnectAppInfo] = []
    
    func getConnectedApps() async -> [UnifiedConnectAppInfo] {
        WalletConnectServiceV2.connectedAppsToUse
    }
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws {
        
    }
    struct WCServiceAppInfo: Hashable {
        var isTrusted: Bool { true }
        func getDisplayName() -> String {
            ""
        }
        func getDappName() -> String {
        ""
        }
        func getDappHostName() -> String {
        ""
        }
        func getChainIds() -> [Int] {
         [8001]
        }
        func getDappHostDisplayName() -> String {
            ""
        }
        func getIconURL() -> URL? {
            nil
        }
    }
}

protocol UnifiedConnectAppInfoProtocol: Equatable, Hashable {
    var walletAddress: HexAddress { get }
    var domain: DomainItem { get }
    var appIconUrls: [String] { get }
    
    var appName: String { get }
    var appUrlString: String { get }
    var displayName: String { get }
    var description: String { get }
    var appInfo: WalletConnectServiceV2.WCServiceAppInfo { get }
    var connectionStartDate: Date? { get }

}

