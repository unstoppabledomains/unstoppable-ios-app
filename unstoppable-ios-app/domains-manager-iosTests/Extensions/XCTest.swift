//
//  XCTest.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 19.07.2022.
//

import Foundation
import XCTest

extension XCTest {
    /// Async equivelent for system XCTAssertEqual
    public func XCTAssertEqualAsync<T>(_ expression1: @autoclosure () async throws -> T, _ expression2: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async throws where T : Equatable {
        let val1 = try await expression1()
        let val2 = try await expression2()
        
        XCTAssertEqual(val1, val2)
    }
    
    public func XCTAssertFalseAsync(_ expression: @autoclosure () async throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async throws {
        let val = try await expression()
        XCTAssertFalse(val)
    }
    
    public func XCTAssertTrueAsync(_ expression: @autoclosure () async throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async throws {
        let val = try await expression()
        XCTAssertTrue(val)
    }
    
    public func XCTAssertNilAsync(_ expression: @autoclosure () async throws -> Any?, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async throws {
        let val = try await expression()
        XCTAssertNil(val)
    }
    
    public func XCTAssertNotNilAsync(_ expression: @autoclosure () async throws -> Any?, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async throws {
        let val = try await expression()
        XCTAssertNotNil(val)
    }
    
    public func XCTAssertThrowsErrorAsync(_ expression: @autoclosure () async throws -> Any?, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async throws {
        do {
            let val = try await expression()
            XCTAssertThrowsError(val)
        } catch {
            return
        }
    }
}
