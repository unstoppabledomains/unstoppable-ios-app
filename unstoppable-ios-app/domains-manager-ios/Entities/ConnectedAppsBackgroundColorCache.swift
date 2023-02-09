//
//  ConnectedAppsImageCache.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.12.2022.
//

import UIKit

actor ConnectedAppsImageCache {
    
    static let shared = ConnectedAppsImageCache()
    
    private var connectedAppToColorCache: [Int : UIColor?] = [:]
    
    private init() { }
    
}

// MARK: - Open methods
extension ConnectedAppsImageCache {
    func colorForApp(_ app: any UnifiedConnectAppInfoProtocol) async -> UIColor? {
        if app.appIconUrls.isEmpty {
            return nil
        } else {
            if let cachedValue = connectedAppToColorCache[app.hashValue] {
                return cachedValue
            }
            
            let icon = await appContext.imageLoadingService.loadImage(from: .connectedApp(app, size: .default), downsampleDescription: nil)
            let color = await icon?.getColors()?.background ?? .brandWhite
            connectedAppToColorCache[app.hashValue] = color
            
            return color
        }
    }
}
