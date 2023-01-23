//
//  WebsiteURLValidatorTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 31.10.2022.
//

import XCTest
@testable import domains_manager_ios

final class WebsiteURLValidatorTests: XCTestCase, WebsiteURLValidator {
    
    func testCorrectWebsite() {
        let validWebsites = ["https://www.website.com", "http://www.website.com", "https://website.com", "http://website.com", "www.website.com", "website.com"]
        validWebsites.forEach { website in
            XCTAssertTrue(isWebsiteValid(website), website)
        }
    }
    
    func testIncorrectWebsite() {
        let invalidWebsites = ["", "website.c", "website", "website .com", "webs!ite.com", "website.com ", " website.com"]
        invalidWebsites.forEach { website in
            XCTAssertFalse(isWebsiteValid(website), website)
        }
    }
    
}
