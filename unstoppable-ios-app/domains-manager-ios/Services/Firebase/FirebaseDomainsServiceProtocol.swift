//
//  FirebaseDomainsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

protocol FirebaseDomainsServiceProtocol {
    var parkedDomainsPublisher: Published<[FirebaseDomainDisplayInfo]>.Publisher  { get }

    func getCachedDomains() -> [FirebaseDomain]
    func getParkedDomains() async throws -> [FirebaseDomain]
    func clearParkedDomains()
}
