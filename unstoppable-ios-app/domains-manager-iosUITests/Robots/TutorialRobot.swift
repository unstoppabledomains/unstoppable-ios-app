//
//  TutorialRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import Foundation
import XCTest

final class TutorialRobot: Robot, DashesProgressRobot {
    
    private lazy var createNewButton = app.buttons["Tutorial Create New Button"]
    private lazy var restoreCreateNewButton = app.buttons["Restore wallet create new button"]
    private lazy var createVaultConfirmButton = app.buttons["Create vault confirm button"]
    private lazy var iHaveButton = app.buttons["Tutorial I Have Button"]

    @discardableResult
    func tapCreateNewButton() -> Self {
        self.tap(createNewButton)
            .tap(restoreCreateNewButton)
            .tap(createVaultConfirmButton)
    }
    
    @discardableResult
    func tapIHaveButton() -> Self {
        self.tap(iHaveButton)
    }
    
    
}
