//
//  TaskWithDeadlineTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 01.03.2024.
//

import XCTest
@testable import domains_manager_ios

class TaskWithDeadlineTests: XCTestCase {
    func testSuccessfulTaskCompletion() async throws {
        let expectedValue = "Test Value"
        let task = TaskWithDeadline(deadline: 1.0) {
            return expectedValue
        }
        
        let value = try await task.value
        XCTAssertEqual(value, expectedValue)
    }
    
    func testTaskCompletesWithinDeadline() async throws {
        let expectedValue = "Test Value"
        let task = TaskWithDeadline(deadline: 1.0) {
            try await Task.sleep(for: .milliseconds(500))
            return expectedValue
        }
        
        let value = try await task.value
        XCTAssertEqual(value, expectedValue)
    }
    
    func testTaskTimeout() async throws {
        let task = TaskWithDeadline(deadline: 0.1) {
            try await Task.sleep(for: .seconds(1))
            return ""
        }
        
        do {
            _ = try await task.value
            XCTFail("Task should not have completed successfully")
        } catch {
            
        }
    }
}
