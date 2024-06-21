//
//  MPCWalletPasswordValidator.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import XCTest
@testable import domains_manager_ios

class MPCWalletPasswordValidatorTests: XCTestCase, MPCWalletPasswordValidator {
    
    func testTooShortPassword() {
        let password = "ABC!@"
        let errors = validateWalletPassword(password)
        XCTAssertEqual(errors, [.tooShort, .missingNumber])
    }
    
    func testTooLongPassword() {
        let password = "A1!@#$%^&*()_+-=A1!@#$%^&*()_+-=A1!@"
        let errors = validateWalletPassword(password)
        XCTAssertEqual(errors, [.tooLong])
    }
    
    func testMissingNumber() {
        let password = "ABC!@ABC!@ABC!"
        let errors = validateWalletPassword(password)
        XCTAssertEqual(errors, [.missingNumber])
    }
    
    func testMissingSpecialCharacter() {
        let password = "ABC123ABC123"
        let errors = validateWalletPassword(password)
        XCTAssertEqual(errors, [.missingSpecialCharacter])
    }
    
    func testValidPassword() {
        let password = "A1!@BCDEFGHIJK"
        let errors = validateWalletPassword(password)
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testMultipleErrors() {
        let password = "short"
        let errors = validateWalletPassword(password)
        XCTAssertEqual(errors, [.tooShort, .missingNumber, .missingSpecialCharacter])
    }
    
    func testAnotherValidPassword() {
        let password = "ValidPassword123!"
        let errors = validateWalletPassword(password)
        XCTAssertTrue(errors.isEmpty)
    }
    
}

