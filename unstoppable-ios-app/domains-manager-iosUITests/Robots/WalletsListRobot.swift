//
//  WalletsListRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import XCTest

final class WalletsListRobot: Robot {
    
    private lazy var collectionView = app.collectionViews["Wallets List Collection View"]
    private lazy var plusButton = app.buttons["Wallets List Plus Button"]
    
    @discardableResult
    func ensurePlusButton(visible: Bool) -> Self {
        assert(exists: visible, [plusButton])
    }
    
    @discardableResult
    func tapPlusButton() -> Self {
        self.tap(plusButton)
    }
    
    @discardableResult
    func ensureNumberOfCells(_ numberOfCells: Int) -> Self {
        XCTAssertEqual(collectionView.cells.count, numberOfCells)
        return self
    }
    
    @discardableResult
    func ensureCell(with name: String, visible: Bool) -> Self {
        assert(exists: visible, [cellWith(name: name)])
    }
    
    @discardableResult
    func tapOnCellWith(name: String) -> Self {
        tap(cellWith(name: name))
    }
    
}

// MARK: - Private methods
private extension WalletsListRobot  {
    func cellWith(name: String) -> XCUIElement {
        return collectionView.cells["Wallets List Collection Cell \(name)"]
    }
}

