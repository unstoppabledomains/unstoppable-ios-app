//
//  CreateBackUpPasswordRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import XCTest

final class CreateBackUpPasswordRobot: Robot, DashesProgressRobot {
    
    private lazy var enterTextField = app.secureTextFields["Create Back Up Password Enter Text Field"]
    private var repeatTextFieldLabel: XCUIElement { app.staticTexts["Confirm password"] }
    private var repeatTextField: XCUIElement { app.secureTextFields["Create Back Up Password Repeat Text Field"] }
    private lazy var doneButton = app.buttons["Create Back Up Password Done Button"]

    @discardableResult
    func ensureConfirmButton(enabled: Bool) -> Self {
        XCTAssertEqual(doneButton.isEnabled, enabled)
        return self
    }
    
    @discardableResult
    func setPassword(_ password: String) -> Self {
        enterTextField.typeText(password)
        return self
    }
    
    @discardableResult
    func clearPasswordInput() -> Self {
        enterTextField.clearText()
        return self
    }
    
    @discardableResult
    func setRepeatPassword(_ password: String) -> Self {
        repeatTextField.typeText(password)
        return self
    }
    
    @discardableResult
    func ensureRepeatPassword(visible: Bool) -> Self {
        if visible {
            XCTAssertEqual(repeatTextFieldLabel.exists, visible)
            tap(repeatTextFieldLabel)
            waitForElementToAppear(repeatTextField)
            return waitForElementToAppear(repeatTextField)
        }
        XCTAssertEqual(repeatTextFieldLabel.exists, visible)
        XCTAssertEqual(repeatTextField.exists, visible)
        return self
    }
    
    @discardableResult
    func tapDone() -> Self {
        tap(doneButton)
    }
    
}
