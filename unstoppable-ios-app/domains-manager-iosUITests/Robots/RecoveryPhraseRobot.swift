//
//  RecoveryPhraseRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import XCTest

final class RecoveryPhraseRobot: Robot, DashesProgressRobot {
    
    private lazy var copyToClipboardButton = app.buttons["Recovery Phrase Copy To Clipboard Button"]
    private lazy var doneButton = app.buttons["Recovery Phrase Done Button"]
    
    @discardableResult
    func tapCopyToClipboard() -> Self {
        tap(copyToClipboardButton)
    }
    
    @discardableResult
    func tapDone() -> Self {
        tap(doneButton)
    }
    
}
