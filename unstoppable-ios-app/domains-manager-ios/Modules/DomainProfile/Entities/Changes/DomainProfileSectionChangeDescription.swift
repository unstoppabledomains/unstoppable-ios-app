//
//  DomainProfileSectionChangeDescription.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.11.2022.
//

import Foundation

struct DomainProfileSectionChangeDescription: Sendable {
    let uiChange: DomainProfileSectionUIChangeType
    let dataChanges: [DomainProfileSectionDataChangeType]
}
