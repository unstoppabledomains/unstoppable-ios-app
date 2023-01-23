//
//  DashesProgressRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import Foundation
import XCTest

protocol DashesProgressRobot { }

extension DashesProgressRobot where Self: Robot {
    
    var dashesProgressView: XCUIElement { app.otherElements["Dashes Progress View"] }
    
    @discardableResult
    func ensureDashesProgressView(visible: Bool) -> Self {
        if visible {
            waitForElementToAppear(dashesProgressView, timeout: 40)
        }
        XCTAssertEqual(dashesProgressView.exists, visible)
        return self
    }
    
    @discardableResult
    func checkDashesProgressView(progress: Double) -> Self {
        let value = Double(dashesProgressView.value as? String ?? "") ?? -1
        XCTAssertEqual(value, progress)
        
        return self
    }
}
