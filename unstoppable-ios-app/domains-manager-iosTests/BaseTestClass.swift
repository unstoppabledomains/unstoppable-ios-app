//
//  BaseTestClass.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 10.11.2022.
//

import XCTest
@testable import domains_manager_ios

class BaseTestClass: XCTestCase {
   
    func waitFor(interval: TimeInterval = 0.2) async throws {
        let duration = UInt64(interval * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
    
}

