//
//  DomainProfileUpdateDataRequestType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.11.2022.
//

import Foundation

enum DomainProfileUpdateDataRequestType {
    case records(_ records: [RecordToUpdate])
    case profile(_ request: ProfileUpdateRequest)
}
