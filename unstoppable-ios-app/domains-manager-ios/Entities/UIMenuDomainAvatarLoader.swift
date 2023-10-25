//
//  UIMenuDomainAvatarLoader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.06.2023.
//

import UIKit

struct UIMenuDomainAvatarLoader {
    
    @MainActor
    static func menuAvatarFor(domain: DomainDisplayInfo,
                              size: CGFloat = 20) async -> UIImage? {
        var avatar = await appContext.imageLoadingService.loadImage(from: .domain(domain),
                                                                    downsampleDescription: .icon)
        
        if let image = avatar {
            avatar = image.circleCroppedImage(size: size)
        } else {
            avatar = await appContext.imageLoadingService.loadImage(from: .domainInitials(domain,
                                                                                          size: .default),
                                                                    downsampleDescription: .icon)
        }
        return avatar
    }
    
}
