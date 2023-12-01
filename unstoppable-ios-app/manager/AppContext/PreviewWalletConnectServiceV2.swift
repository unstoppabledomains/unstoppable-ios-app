//
//  PreviewWalletConnectServiceV2.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

protocol WalletConnectServiceV2Protocol {
    
}

final class WalletConnectServiceV2: WalletConnectServiceV2Protocol {
    struct WCServiceAppInfo {
        func getDisplayName() -> String {
            ""
        }
    }
}

protocol UnifiedConnectAppInfoProtocol: Equatable, Hashable {
    var displayName: String { get }
}

