//
//  RequestsLimitController.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 24.05.2024.
//

@testable import domains_manager_ios
import XCTest

final class RequestsLimitControllerTests: XCTestCase {
    let requestLimit: Int = 5
    let timeInterval: TimeInterval = 1.0 // 1 second for testing
    var requestsLimitController: RequestsLimitController!
    
    override func setUp() {
        super.setUp()
        requestsLimitController = RequestsLimitController(requestLimit: requestLimit, timeInterval: timeInterval)
    }
    
    func testRateLimiterExceedingLimit() async {
        for _ in 0..<requestLimit {
            await requestsLimitController.acquirePermission()
        }
        
        let start = Date()
        await requestsLimitController.acquirePermission()
        let end = Date()
        
        XCTAssertTrue(end.timeIntervalSince(start) >= timeInterval, "Exceeded limit should wait for the time interval to pass")
    }
    
    func testRateLimiterClearsOldTimestamps() async {
        for _ in 0..<requestLimit {
            await requestsLimitController.acquirePermission()
        }
        
        // Wait enough time to clear old timestamps
        await Task.sleep(seconds: timeInterval + 0.1)
        
        let start = Date()
        await requestsLimitController.acquirePermission()
        let end = Date()
        
        XCTAssertTrue(end.timeIntervalSince(start) < timeInterval, "Should not wait after clearing old timestamps")
    }
}
