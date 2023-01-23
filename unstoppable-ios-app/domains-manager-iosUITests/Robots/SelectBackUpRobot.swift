//
//  SelectBackUpRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import XCTest

final class SelectBackUpRobot: Robot, DashesProgressRobot {
    
    private lazy var tableView = app.tables["Select BackUp Table View"]
    
    @discardableResult
    func waitTillAppear() -> Self {
        waitForElementToAppear(tableView)
    }
    
    @discardableResult
    func ensureNumberOfCells(_ numberOfCells: Int) -> Self {
        XCTAssertEqual(tableView.cells.count, numberOfCells)
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
private extension SelectBackUpRobot  {
    func cellWith(name: String) -> XCUIElement {
        return tableView.cells["Select BackUp Table View Cell \(name)"]
    }
}

