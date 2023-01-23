//
//  ProtectWalletRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import XCTest

final class ProtectWalletRobot: Robot, DashesProgressRobot {
    
    private lazy var tableView = app.tables["Protect Wallet Table View"]
    
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
private extension ProtectWalletRobot  {
    func cellWith(name: String) -> XCUIElement {
        return tableView.cells["Protect Wallet Table View Cell \(name)"]
    }
}



