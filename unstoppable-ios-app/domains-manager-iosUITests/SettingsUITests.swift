//
//  SettingsUITests.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import Foundation
import XCTest
import MessageUI

final class SettingsUITests: BaseXCTestCase {
    
    override var launchEnvironment: [String : String] { [TestsEnvironment.numberOfDomains.rawValue : "0"] }

    func testInitialState() {
        let canSendMail = MFMailComposeViewController.canSendMail()
        
        NavigationRobot(app)
            .openSettings()
        
        SettingsRobot(app)
            .ensureNumberOfCells(canSendMail ? 7 : 6)
    }
    
}
