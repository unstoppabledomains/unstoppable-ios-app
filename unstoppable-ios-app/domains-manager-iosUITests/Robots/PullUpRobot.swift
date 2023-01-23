//
//  PullUpRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import XCTest

final class PullUpRobot: Robot {
    
    private lazy var collectionView = app.collectionViews["Pull Up Collection View"]
    private lazy var confirmButton = app.buttons["Pull Up Confirm Button"]
    private lazy var cancelButton = app.buttons["Pull Up Cancel Button"]
    private lazy var pullUpView = app.otherElements["Pull Up View"]

    @discardableResult
    func tapConfirm() -> Self {
        tap(confirmButton)
    }
    
    @discardableResult
    func tapCancel() -> Self {
        tap(cancelButton)
    }
    
    @discardableResult
    func dismissByTap() -> Self {
        tap(pullUpView)
    }
    
    @discardableResult
    func ensureNumberOfCells(_ numberOfCells: Int) -> Self {
        XCTAssertEqual(collectionView.cells.count, numberOfCells)
        return self
    }
    
    @discardableResult
    func ensureCellPresent(name: String) -> Self {
        assertExists([cellWith(name: name)])
    }
    
    @discardableResult
    func tapOnCellWith(name: String) -> Self {
        tap(cellWith(name: name))
    }
}

// MARK: - Private methods
private extension PullUpRobot  {
    func cellWith(name: String) -> XCUIElement {
        return collectionView.cells["Pull Up Collection View Cell \(name)"]
    }
}
