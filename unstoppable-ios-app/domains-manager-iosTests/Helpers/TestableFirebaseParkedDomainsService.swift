//
//  TestableFirebaseParkedDomainsService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 19.03.2024.
//

import Foundation
@testable import domains_manager_ios
import Combine

final class TestableFirebaseParkedDomainsService: FirebaseDomainsServiceProtocol, FailableService {
    var shouldFail: Bool = false
    var domainsToReturn: [FirebaseDomain] = []
    
    @Published var parkedDomains: [FirebaseDomainDisplayInfo] = []
    var parkedDomainsPublisher: Published<[FirebaseDomainDisplayInfo]>.Publisher  { $parkedDomains }
    
    var numberOfGetCachedDomainsCalls = 0
    func getCachedDomains() -> [FirebaseDomain] {
        numberOfGetCachedDomainsCalls += 1
        return domainsToReturn
    }
    
    func getParkedDomains() async throws -> [FirebaseDomain] {
        try failIfNeeded()
        
        return domainsToReturn
    }
}
