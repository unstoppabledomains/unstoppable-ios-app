//
//  SettingsRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import XCTest

final class SettingsRobot: Robot {
    
    private lazy var collectionView = app.collectionViews["Settings Collection View"]
    
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
private extension SettingsRobot  {
    func cellWith(name: String) -> XCUIElement {
        return collectionView.cells["Settings Collection Cell \(name)"]
    }
}
