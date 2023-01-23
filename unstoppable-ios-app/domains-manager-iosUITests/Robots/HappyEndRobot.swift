//
//  HappyEndRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import Foundation
import XCTest

final class HappyEndRobot: Robot, DashesProgressRobot {
    
    private lazy var agreeCheckbox = app.otherElements["Happy End Agree Checkbox"]
    private lazy var getStartedButton = app.buttons["Happy End Get Started Button"]
    
    @discardableResult
    func tapAgreeCheckbox() -> Self {
        tap(agreeCheckbox)
    }
    
    func ensureGetStartedButton(enabled: Bool) -> Self {
        XCTAssertEqual(getStartedButton.isEnabled, enabled)
        return self
    }
    
    @discardableResult
    func tapGetStarted() -> Self {
        tap(getStartedButton)
    }
    
}
