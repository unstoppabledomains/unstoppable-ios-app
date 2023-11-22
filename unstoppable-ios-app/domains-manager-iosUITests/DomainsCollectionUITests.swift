//
//  HomeScreenUITests.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import XCTest

final class DomainsCollectionUIEmptyStateTests: BaseXCTestCase {
    
    override var launchEnvironment: [String : String] { [TestsEnvironment.numberOfDomains.rawValue : "0"] }
    
    func testEmptyState() {
        DomainsCollectionScreenRobot(app)
            .ensurePlusButton(visible: false)
            .ensureVisualisationControl(visible: false)
            .ensureScanButton(visible: false)
            .ensureNumberOfCells(3)
            .ensureCellWith(name: "Import Wallet", visible: true)
            .ensureCellWith(name: "External", visible: true)
    }
    
}
