//
//  LaunchPerformanceTest.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import XCTest

final class LaunchPerformanceTest: BaseXCTestCase {
    
    /// Measure launch app performance.
    /// Make func start with 'test' to make it functional.
    func doNotTestLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
}
