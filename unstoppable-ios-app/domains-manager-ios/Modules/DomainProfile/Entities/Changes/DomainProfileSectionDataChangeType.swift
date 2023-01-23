//
//  DomainProfileSectionDataChangeType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.11.2022.
//

import Foundation

enum DomainProfileSectionDataChangeType: Hashable {
    case record(_ record: CryptoRecord)
    case profileNotDataAttribute(_ attribute: ProfileUpdateRequestNotDataAttribute)
    case profileDataAttribute(_ attribute: ProfileUpdateRequestDataAttribute)
    case profileSocialAccount(_ account: SocialAccount)
    case onChainAvatar(_ address: String)
}

struct ProfileUpdateRequestNotDataAttribute: Hashable {
    let attribute: ProfileUpdateRequest.Attribute
    
    init?(attribute: ProfileUpdateRequest.Attribute) {
        switch attribute {
        case .data:
            return nil
        default:
            self.attribute = attribute
        }
    }
}

struct ProfileUpdateRequestDataAttribute: Hashable {
    let attribute: ProfileUpdateRequest.Attribute
    let data: Set<ProfileUpdateRequest.Attribute.VisualData>
    
    init?(attribute: ProfileUpdateRequest.Attribute) {
        switch attribute {
        case .data(let data):
            self.attribute = attribute
            self.data = data
        default:
            return nil
        }
    }
}
