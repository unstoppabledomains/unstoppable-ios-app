//
//  UnifiedConnectedAppInfoHolder.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import Foundation

struct UnifiedConnectedAppInfoHolder: Hashable, Sendable {
    let app: any UnifiedConnectAppInfoProtocol
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.app.isEqual(rhs.app)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(app)
    }
}
