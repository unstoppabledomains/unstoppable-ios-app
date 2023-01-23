//
//  DomainProfileSectionType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import Foundation

enum DomainProfileSectionType {
    case topInfo(data: DomainProfileTopInfoSection.SectionData)
    case updatingRecords(data: DomainProfileUpdatingRecordsSection.SectionData)
    case generalInfo(data: DomainProfileGeneralInfoSection.SectionData)
    case socials(data: DomainProfileSocialsSection.SectionData)
    case crypto(data: DomainProfileCryptoSection.SectionData)
    case badges(data: DomainProfileBadgesSection.SectionData)
    case web3Website(data: DomainProfileWeb3WebsiteSection.SectionData)
    case metadata(data: DomainProfileMetadataSection.SectionData)
}

