//
//  RenameWalletRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import XCTest

final class RenameWalletRobot: Robot {
    
    private lazy var renameScreen = app.otherElements["Rename Wallet Screen"]
    private lazy var textField = app.textFields["Rename Wallet Text Field"]
    private lazy var doneButton = app.buttons["Rename Wallet Done Button"]
    private lazy var backButton = app.buttons["Empty Navigation Back Button"]
    
    @discardableResult
    func ensureRenameScreen(visible: Bool) -> Self {
        assert(exists: visible, [renameScreen])
    }
    
    func ensureConfirmButton(enabled: Bool) -> Self {
        XCTAssertEqual(doneButton.isEnabled, enabled)
        return self
    }
    
    func setNewWalletName(_ name: String) -> Self {
        textField.typeText(name)
        return self
    }
    
    func clearInput() -> Self {
        textField.clearText()
        return self
    }
    
    @discardableResult
    func confirmRenameWallet() -> Self {
        tap(doneButton)
    }
    
    @discardableResult
    func cancelRenameWallet() -> Self {
        tap(backButton)
    }
}
