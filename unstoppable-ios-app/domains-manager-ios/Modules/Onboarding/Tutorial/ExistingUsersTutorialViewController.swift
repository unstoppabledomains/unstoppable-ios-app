//
//  ExistingUsersTutorialViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.04.2022.
//

import UIKit

final class ExistingUsersTutorialViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var continueButton: MainButton!
    
    var onboardingManager: OnboardingFlowManager!
    override var analyticsName: Analytics.ViewName { .onboardingExistingUserTutorial }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

// MARK: - Actions
private extension ExistingUsersTutorialViewController {
    @IBAction func continueButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .continue)
        let isBiometricOn = User.instance.getSettings().touchIdActivated
        if isBiometricOn {
            onboardingManager.moveToStep(.backupWallet)
        } else {
            onboardingManager.moveToStep(.protectWallet)
        }
    }
}

// MARK: - Setup methods
private extension ExistingUsersTutorialViewController {
    func setup() {
        localizeContent()
    }
    
    func localizeContent() {
        titleLabel.setTitle(String.Constants.existingUsersTutorialTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.existingUsersTutorialSubtitle.localized())
        continueButton.setTitle(String.Constants.continue.localized(), image: nil)
    }
}
