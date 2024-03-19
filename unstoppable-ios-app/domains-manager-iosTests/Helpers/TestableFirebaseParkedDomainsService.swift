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
    
    @Published var parkedDomains: [FirebaseDomainDisplayInfo] = []
    var parkedDomainsPublisher: Published<[FirebaseDomainDisplayInfo]>.Publisher  { $parkedDomains }
    
    func getCachedDomains() -> [FirebaseDomain] {
        []
    }
    
    func getParkedDomains() async throws -> [FirebaseDomain] {
        []
    }
}
