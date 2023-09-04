//
//  ProfileFollowerImageLoader.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 29.08.2023.
//

import UIKit

protocol ProfileImageLoader { }

extension ProfileImageLoader {
    func loadIconFor(follower: DomainProfileFollowerDisplayInfo) async -> UIImage? {
        return await loadIconFor(domainName: follower.domain)
    }
    
    func loadIconOrInitialsFor(follower: DomainProfileFollowerDisplayInfo) async -> UIImage? {
        if let icon = await loadIconFor(domainName: follower.domain) {
            return icon
        }
        return await loadInitialsFor(domainName: follower.domain)
    }
    
    func loadIconFor(domainName: DomainName) async -> UIImage? {
        if let pfpInfo = await appContext.udDomainsService.loadPFP(for: domainName) {
            return await appContext.imageLoadingService.loadImage(from: .domainPFPSource(pfpInfo.source),
                                                                  downsampleDescription: nil)
        }
        return nil
    }
    
    func loadInitialsFor(domainName: DomainName) async -> UIImage? {
        await appContext.imageLoadingService.loadImage(from: .initials(domainName,
                                                                       size: .default,
                                                                       style: .accent),
                                                       downsampleDescription: nil)
    }
}
