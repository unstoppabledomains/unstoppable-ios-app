//
//  MessagingChatUserDisplayInfoImageLoader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.02.2024.
//

import UIKit

final class MessagingChatUserDisplayInfoImageLoader {
    
    static let shared = MessagingChatUserDisplayInfoImageLoader()
    private let initialsSize: InitialsView.InitialsSize = .default
    private var cacheStorage = MessagingChatUserDisplayInfoImageLoaderCacheTracker()

    private init() { }
    
    func getLatestProfileImage(for userInfo: MessagingChatUserDisplayInfo) -> AsyncStream<UIImage?> {
        AsyncStream { continuation in
            Task {
                if cacheStorage.isInfoCached(for: userInfo) {
                    let image = await loadUserImage(for: userInfo)
                    continuation.yield(image)
                    continuation.finish()
                    return
                }
                
                let initialsImage = await loadInitialsImage(for: userInfo)
                continuation.yield(initialsImage)
                
                let refreshedImage = await loadRefreshedUserImage(for: userInfo)
                continuation.yield(refreshedImage)
                
                cacheStorage.saveInfoCached(for: userInfo)
                
                continuation.finish()
            }
        }
    }
    
    private func loadInitialsImage(for userInfo: MessagingChatUserDisplayInfo) async -> UIImage? {
        let name = userInfo.displayName
        let initialsImage = await appContext.imageLoadingService.loadImage(from: .initials(name,
                                                                                           size: initialsSize,
                                                                                           style: .accent),
                                                                           downsampleDescription: nil)
        return initialsImage
    }
    
    private func loadRefreshedUserImage(for userInfo: MessagingChatUserDisplayInfo) async -> UIImage? {
        let refreshedProfile = await appContext.messagingService.refreshUserDisplayInfo(of: userInfo)
        let refreshedImage = await loadUserImage(for: refreshedProfile)
        return refreshedImage
    }
    
    private func loadUserImage(for userInfo: MessagingChatUserDisplayInfo) async -> UIImage? {
        let image = await appContext.imageLoadingService.loadImage(from: .messagingUserPFPOrInitials(userInfo,
                                                                                                     size: initialsSize), 
                                                                   downsampleDescription: .mid)
        return image
    }
}

private final class MessagingChatUserDisplayInfoImageLoaderCacheTracker {
    private let serialQueue = DispatchQueue(label: "com.messaging.image.loader")
    private var cache: Set<HexAddress> = []
    
    func isInfoCached(for userInfo: MessagingChatUserDisplayInfo) -> Bool {
        let cacheKey = getCacheKey(for: userInfo)
        
        return serialQueue.sync { cache.contains(cacheKey) }
    }
    
    func saveInfoCached(for userInfo: MessagingChatUserDisplayInfo) {
        let cacheKey = getCacheKey(for: userInfo)
        
        _ = serialQueue.sync { cache.insert(cacheKey) }
    }
    
    private func getCacheKey(for userInfo: MessagingChatUserDisplayInfo) -> String {
        userInfo.wallet
    }
}
