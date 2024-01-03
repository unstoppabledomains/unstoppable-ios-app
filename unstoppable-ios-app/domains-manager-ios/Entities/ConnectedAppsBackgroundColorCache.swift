//
//  ConnectedAppsImageCache.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.12.2022.
//

import UIKit

actor ConnectedAppsImageCache {
    
    static let shared = ConnectedAppsImageCache()
    
    private var connectedAppToColorCache: [String : UIColor] = [:]
    
    private init() {
        Task {
            await loadFromCache()
        }
    }
    
}

// MARK: - Open methods
extension ConnectedAppsImageCache {
    func colorForApp(_ app: any UnifiedConnectAppInfoProtocol) async -> UIColor? {
        if app.appIconUrls.isEmpty {
            return nil
        } else {
            let imageSource: ImageSource = .connectedApp(app, size: .default)
            if let cachedValue = connectedAppToColorCache[imageSource.key] {
                return cachedValue
            }
            
            let icon = await appContext.imageLoadingService.loadImage(from: imageSource, downsampleDescription: nil)
            let color = await icon?.getColors()?.background ?? .brandWhite
            connectedAppToColorCache[imageSource.key] = color
            
            saveCache()
            
            return color
        }
    }
}

// MARK: - Private methods
private extension ConnectedAppsImageCache {
    func loadFromCache() {
        let cachedMap = ConnectedAppsColorsStorage.instance.getConnectedAppToColorMap()
        
        for (key, data) in cachedMap {
            if let color = UIColor.color(data: data) {
                connectedAppToColorCache[key] = color
            } else {
                Debugger.printFailure("Failed to unarchive uicolor from data for key \(key)", critical: true)
            }
        }
    }
    
    func saveCache() {
        var cachedMap = ConnectedAppToColorMap()
        
        for (key, color) in connectedAppToColorCache {
            if let data = color.encode() {
                cachedMap[key] = data
            } else {
                Debugger.printFailure("Failed to encode uicolor to data for key \(key)", critical: true)
            }
        }
        
        ConnectedAppsColorsStorage.instance.set(newConnectedAppToColorMap: cachedMap)
    }
}

private extension UIColor {
    static func color(data: Data) -> UIColor? {
        guard let hex = String(data: data, encoding: .utf8) else { return nil }
        
        return UIColor(hex: hex)
    }
    
    func encode() -> Data? {
        self.toHex().data(using: .utf8)
    }
}

typealias ConnectedAppToColorMap = [String : Data]

private final class ConnectedAppsColorsStorage {
    
    static let connectedAppsToColorFileName = "connected-apps-colors.data"
    
    private init() {}
    static var instance = ConnectedAppsColorsStorage()
    
    private var storage = SpecificStorage<ConnectedAppToColorMap>(fileName: ConnectedAppsColorsStorage.connectedAppsToColorFileName)
    
    func getConnectedAppToColorMap() -> ConnectedAppToColorMap {
        storage.retrieve() ?? [:]
    }
    
    func set(newConnectedAppToColorMap: ConnectedAppToColorMap) {
        storage.store(newConnectedAppToColorMap)
    }
}
