//
//  HomeScreenRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import XCTest

final class DomainsCollectionScreenRobot: Robot {
    
    private lazy var settingsButton = app.buttons["Domains Collection Settings Button"]
    private lazy var plusButton = app.buttons["Domains Collection Plus Button"]
    private lazy var scanButton = app.buttons["Domains Collection Scan Button"]
    private lazy var visualisationControl = app.otherElements["Domains Collection Visualisation Control"]
    private lazy var collectionView = app.collectionViews["Domains Collection Collection View"]

    @discardableResult
    func tapSettings() -> Self {
        return tap(settingsButton)
    }
    
    func ensurePlusButton(visible: Bool) -> Self {
        assert(exists: visible, [plusButton])
    }
    
    func ensureVisualisationControl(visible: Bool) -> Self {
        assert(exists: visible, [visualisationControl])
    }
    
    func ensureScanButton(visible: Bool) -> Self {
        assert(exists: visible, [scanButton])
    }
    
    @discardableResult
    func ensureNumberOfCells(_ numberOfCells: Int) -> Self {
        XCTAssertEqual(collectionView.cells.count, numberOfCells)
        return self
    }
    
    @discardableResult
    func ensureCellWith(name: String, visible: Bool) -> Self {
        assert(exists: visible, [cellWith(name: name)])
    }
    
    @discardableResult
    func tapOnCellWith(name: String) -> Self {
        tap(cellWith(name: name))
    }
}

// MARK: - Private methods
private extension DomainsCollectionScreenRobot  {
    func cellWith(name: String) -> XCUIElement {
        return collectionView.cells["Domains Collection Cell \(name)"]
    }
}
