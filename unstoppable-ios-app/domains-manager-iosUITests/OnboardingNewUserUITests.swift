//
//  OnboardingNewUserUITests.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import Foundation
import XCTest

class OnboardingNewUserUITests: BaseXCTestCase {
    
    override var launchEnvironment: [String : String] { [TestsEnvironment.launchState.rawValue : TestsEnvironment.AppLaunchState.onboardingNew.rawValue].merging(extraLaunchEnvironment, uniquingKeysWith: { $1} ) }
    var extraLaunchEnvironment: [String : String] { [:] }
    
}

// TODO: - Check info screens
// TODO: - Check Back navigation

final class OnboardingNewUserCreateBackUpCloudTest: OnboardingNewUserUITests {
    func testCreateNewVaultBackup() {
        let password = "12345678qwerty1"
        
        TutorialRobot(app)
            .ensureDashesProgressView(visible: false)
            .tapCreateNewButton()
        
        ProtectWalletRobot(app)
            .ensureDashesProgressView(visible: true)
            .checkDashesProgressView(progress: 0.25)
            .ensureBackButton(visible: true)
            .tapOnCellWith(name: "Use Face ID")
        
        SelectBackUpRobot(app)
            .ensureDashesProgressView(visible: true)
            .checkDashesProgressView(progress: 0.75)
            .waitTillAppear()
            .ensureBackButton(visible: true)
            .ensureNumberOfCells(2)
            .tapOnCellWith(name: "Back up to iCloud")
        
        CreateBackUpPasswordRobot(app)
            .ensureDashesProgressView(visible: true)
            .checkDashesProgressView(progress: 0.75)
            .ensureBackButton(visible: true)
            .ensureConfirmButton(enabled: false)
            .ensureRepeatPassword(visible: false)
            .setPassword("123")
            .ensureRepeatPassword(visible: false)
            .clearPasswordInput()
            .ensureRepeatPassword(visible: false)
            .setPassword(password)
            .ensureConfirmButton(enabled: false)
            .ensureRepeatPassword(visible: true)
            .setRepeatPassword(password)
            .ensureConfirmButton(enabled: true)
            .setRepeatPassword(XCUIKeyboardKey.delete.rawValue)
            .ensureConfirmButton(enabled: false)
            .setRepeatPassword("1")
            .tapDone()
            
        RecoveryPhraseRobot(app)
            .ensureDashesProgressView(visible: true)
            .checkDashesProgressView(progress: 1)
            .ensureBackButton(visible: false)
            .tapCopyToClipboard()
            .tapDone()
        
        HappyEndRobot(app)
            .ensureDashesProgressView(visible: false)
            .ensureBackButton(visible: false)
            .ensureGetStartedButton(enabled: false)
            .tapAgreeCheckbox()
            .ensureGetStartedButton(enabled: true)
            .tapAgreeCheckbox()
            .ensureGetStartedButton(enabled: false)
            .tapAgreeCheckbox()
            .tapGetStarted()
        
    }
}

final class OnboardingNewUserCreateBackUpManuallyTest: OnboardingNewUserUITests {
    
    override var extraLaunchEnvironment: [String : String] { [TestsEnvironment.isICloudAvailable.rawValue : "0"] }
    
    func testCreateNewVaultBackup() {
        TutorialRobot(app)
            .tapCreateNewButton()
        
        ProtectWalletRobot(app)
            .ensureDashesProgressView(visible: true)
            .tapOnCellWith(name: "Use Face ID")
        
        SelectBackUpRobot(app)
            .waitTillAppear()
            .ensureNumberOfCells(1)
            .tapOnCellWith(name: "Back up manually")
        
        RecoveryPhraseRobot(app)
            .ensureDashesProgressView(visible: true)
            .checkDashesProgressView(progress: 0.75)
            .ensureBackButton(visible: true)
            .tapCopyToClipboard()
            .tapDone()
        
        ConfirmRecoveryWordsRobot(app)
            .ensureDashesProgressView(visible: true)
            .checkDashesProgressView(progress: 0.75)
            .ensureBackButton(visible: true)
//            .ensureNumberOfConfirmCells(12)
            .tapForgotWords()
    }
}
