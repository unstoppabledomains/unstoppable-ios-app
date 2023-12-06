//
//  DomainProfilePendingChanges.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.12.2023.
//

import UIKit

struct DomainProfilePendingChanges: Codable, Hashable {
    let domainName: String 
    var avatarData: Data?
    var bannerData: Data?
    var name: String?
    var bio: String?
    var location: String?
    var website: String?
    
    var isEmpty: Bool {
        avatarData == nil &&
        bannerData == nil &&
        name == nil &&
        bio == nil &&
        location == nil &&
        website == nil
    }
    
    var updateAttributes: ProfileUpdateRequest.AttributeSet {
        var attributes = ProfileUpdateRequest.AttributeSet()
        
        if let avatarData {
            attributes.insert(.data([.init(kind: .personalAvatar, 
                                           base64: avatarData.base64EncodedString(),
                                           type: .png)]))
        }
        if let bannerData {
            attributes.insert(.data([.init(kind: .banner,
                                           base64: bannerData.base64EncodedString(),
                                           type: .png)]))
        }
        
        if let name {
            attributes.insert(.name(name))
        }
        if let bio {
            attributes.insert(.bio(bio))
        }
        if let location {
            attributes.insert(.location(location))
        }
        if let website {
            attributes.insert(.website(website))
        }
        
        return attributes
    }
    
    func getAvatarImage() async -> UIImage? {
        if let avatarData {
            return await UIImage.createWith(anyData: avatarData)
        }
        return nil
    }
}