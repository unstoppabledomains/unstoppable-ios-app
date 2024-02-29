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
    private var cacheStorage = MessagingChatUserDisplayInfoImageLoaderCacheStorage()

    private init() { }
    
    func getLatestProfileImage(for userInfo: MessagingChatUserDisplayInfo) -> AsyncStream<UIImage?> {
        AsyncStream { continuation in
            Task {
                if let cachedImage = cacheStorage.getImageFromCache(for: userInfo) {
                    continuation.yield(cachedImage)
                    continuation.finish()
                    return
                }
                
                let initialsImage = await loadInitialsImage(for: userInfo)
                continuation.yield(initialsImage)
                
                let refreshedImage = await loadRefreshedUserImage(for: userInfo)
                continuation.yield(refreshedImage)
                
                cacheStorage.saveImageToCache(for: userInfo, image: refreshedImage)
                
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
        let refreshedImage = await appContext.imageLoadingService.loadImage(from: .messagingUserPFPOrInitials(refreshedProfile,
                                                                                                              size: initialsSize), downsampleDescription: .mid)
        return refreshedImage
    }
}

private final class MessagingChatUserDisplayInfoImageLoaderCacheStorage {
    private let serialQueue = DispatchQueue(label: "com.messaging.image.loader")
    private var imagesCache: [HexAddress : UIImage?] = [:]
    
    func getImageFromCache(for userInfo: MessagingChatUserDisplayInfo) -> Optional<UIImage?> {
        let cacheKey = getCacheKey(for: userInfo)
        
        return serialQueue.sync { imagesCache[cacheKey] }
    }
    
    func saveImageToCache(for userInfo: MessagingChatUserDisplayInfo,
                                  image: UIImage?) {
        let cacheKey = getCacheKey(for: userInfo)
        
        serialQueue.sync { imagesCache[cacheKey] = image }
    }
    
    private func getCacheKey(for userInfo: MessagingChatUserDisplayInfo) -> String {
        userInfo.wallet
    }
}
