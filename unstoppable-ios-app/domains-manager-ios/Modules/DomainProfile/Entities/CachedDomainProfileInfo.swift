//
//  CachedDomainProfileInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.11.2022.
//

import Foundation

struct CachedDomainProfileInfo: Codable {
    let domainName: String
    let recordsData: DomainRecordsData
    let badgesInfo: BadgesInfo
    let profile: SerializedUserDomainProfile
}
