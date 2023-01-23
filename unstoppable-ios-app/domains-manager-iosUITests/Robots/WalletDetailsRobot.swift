//
//  WalletDetailsRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import XCTest

final class WalletDetailsRobot: Robot {
    
    private lazy var collectionView = app.collectionViews["Wallet Details Collection View"]
    
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
private extension WalletDetailsRobot  {
    func cellWith(name: String) -> XCUIElement {
        return collectionView.cells["Wallet Details Collection Cell \(name)"]
    }
}

