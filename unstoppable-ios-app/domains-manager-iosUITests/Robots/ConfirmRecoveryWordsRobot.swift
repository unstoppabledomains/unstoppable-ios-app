//
//  ConfirmRecoveryWordsRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import XCTest

final class ConfirmRecoveryWordsRobot: Robot, DashesProgressRobot {
    
    private lazy var forgotWordsButton = app.buttons["Confirm Recovery Words Forgot Button"]
    private lazy var confirmWordCollectionView = app.collectionViews["Confirm Recovery Words Confirm Collection View"]
   
    @discardableResult
    func tapForgotWords() -> Self {
        return tap(forgotWordsButton)
    }
   
    @discardableResult
    func ensureNumberOfConfirmCells(_ numberOfCells: Int) -> Self {
        XCTAssertEqual(confirmWordCollectionView.cells.count, numberOfCells)
        return self
    }
    
    @discardableResult
    func ensureConfirmCellPresent(name: String) -> Self {
        assertExists([confirmCellWith(name: name)])
    }
    
    @discardableResult
    func tapOnConfirmCellWith(name: String) -> Self {
        tap(confirmCellWith(name: name))
    }
}

// MARK: - Private methods
private extension ConfirmRecoveryWordsRobot  {
    func confirmCellWith(name: String) -> XCUIElement {
        return confirmWordCollectionView.cells["Confirm Recovery Words Confirm Collection Cell \(name)"]
    }
}
