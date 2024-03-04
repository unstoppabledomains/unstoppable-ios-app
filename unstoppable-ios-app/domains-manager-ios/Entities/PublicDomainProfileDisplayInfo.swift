//
//  PublicDomainProfileDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation

struct PublicDomainProfileDisplayInfo {
    let domainName: String
    let ownerWallet: String
    let profileName: String?
    let pfpURL: URL?
    let imageType: DomainProfileImageType?
    let bannerURL: URL?
}

extension PublicDomainProfileDisplayInfo {
    init(serializedProfile: SerializedPublicDomainProfile) {
        self.domainName = serializedProfile.metadata.domain
        self.ownerWallet = serializedProfile.metadata.owner
        self.profileName = serializedProfile.profile.displayName
        self.pfpURL = URL(string: serializedProfile.profile.imagePath ?? "")
        self.imageType = serializedProfile.profile.imageType
        self.bannerURL = URL(string: serializedProfile.profile.coverPath ?? "")
    }
}
