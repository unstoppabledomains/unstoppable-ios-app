//
//  PreviewConnectedAppsImageCache.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import UIKit

final class ConnectedAppsImageCache {
    
    static let shared = ConnectedAppsImageCache()
    
    private init() { }
    
    func colorForApp(_ app: any UnifiedConnectAppInfoProtocol) async -> UIColor? {
        nil
    }
}
