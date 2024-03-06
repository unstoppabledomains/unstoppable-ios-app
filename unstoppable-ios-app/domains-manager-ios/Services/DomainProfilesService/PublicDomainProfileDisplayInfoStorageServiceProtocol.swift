//
//  PublicDomainProfileDisplayInfoStorageServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.03.2024.
//

import Foundation

protocol PublicDomainProfileDisplayInfoStorageServiceProtocol {
    func store(profile: DomainProfileDisplayInfo)
    func retrieveProfileFor(domainName: DomainName) throws -> DomainProfileDisplayInfo
}
