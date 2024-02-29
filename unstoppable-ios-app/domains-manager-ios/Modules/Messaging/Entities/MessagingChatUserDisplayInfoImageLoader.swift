//
//  MessagingChatUserDisplayInfoImageLoader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.02.2024.
//

import UIKit

struct MessagingChatUserDisplayInfoImageLoader {
    
    private let initialsSize: InitialsView.InitialsSize = .default
    
    func getLatestProfileImage(for userInfo: MessagingChatUserDisplayInfo) -> AsyncStream<UIImage?> {
        AsyncStream { continuation in
            Task {
                let initialsImage = await loadInitialsImage(for: userInfo)
                continuation.yield(initialsImage)
                
                let refreshedImage = await loadRefreshedUserImage(for: userInfo)
                continuation.yield(refreshedImage)
                
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
