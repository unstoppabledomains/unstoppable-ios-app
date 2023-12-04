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
    func getConnectedApps() async -> [UnifiedConnectAppInfo] {
        [.init(walletAddress: "",
               appIconUrls: [],
               appName: "Uniswap",
               appUrlString: "",
               displayName: "Uniswap",
               description: "",
               appInfo: .init(),
               domain: .init(name: "oleg.x"))]
    }
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws {
        
    }
    struct WCServiceAppInfo: Hashable {
        func getDisplayName() -> String {
            ""
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

