//
//  HappyEndViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 23.03.2022.
//

import UIKit

final class HappyEndViewController: BaseViewController {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var confettiImageView: ConfettiImageView!
    @IBOutlet private weak var agreementTextView: UITextView!
    @IBOutlet private weak var getStartedButton: MainButton!
    @IBOutlet private weak var checkboxContainer: UIView!
    @IBOutlet private weak var checkbox: UDCheckBox!
    
    private let termsOfUseText = String.Constants.termsOfUse.localized()
    private let privacyPolicyText = String.Constants.privacyPolicy.localized()
    override var isNavBarHidden: Bool { true }
    override var analyticsName: Analytics.ViewName { .onboardingHappyEnd }

    static func instance() -> HappyEndViewController {
        HappyEndViewController.storyboardInstance(from: .happyEnd)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        confettiImageView.startConfettiAnimationAsync()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Vibration.success.vibrate()
    }
    
}

// MARK: - Actions
private extension HappyEndViewController {
    @IBAction func didTapSwitch(_ sender: UDCheckBox) {
        getStartedButton.isEnabled = sender.isOn
        logButtonPressedAnalyticEvents(button: .agreeCheckbox, parameters: [.isOn : String(checkbox.isOn)])
    }
    
    @IBAction func didTapGetStartedButton(_ sender: MainButton) {
        if UserDefaults.onboardingData?.didRestoreWalletsFromBackUp == true {
            AppReviewService.shared.appReviewEventDidOccurs(event: .didRestoreWalletsFromBackUp)
        }
        UserDefaults.onboardingNavigationInfo = nil
        UserDefaults.onboardingData = nil
        
        var settings = User.instance.getSettings()
        settings.onboardingDone = true
        User.instance.update(settings: settings)
        
        ConfettiImageView.releaseAnimations()
        appContext.coreAppCoordinator.showHome(mintingState: .default)
        logButtonPressedAnalyticEvents(button: .getStarted)
    }
    
    @objc func didTapCheckboxContainer() {
        UDVibration.buttonTap.vibrate()
        checkbox.isOn.toggle()
        getStartedButton.isEnabled = checkbox.isOn
        logButtonPressedAnalyticEvents(button: .agreeCheckbox, parameters: [.isOn : String(checkbox.isOn)])
    }
    
    @objc func didTapAgreementTextView(_ tapGesture: UITapGestureRecognizer) {
        let point = tapGesture.location(in: agreementTextView)
        if let detectedWord = getWordAtPosition(point) {
            if termsOfUseText.contains(detectedWord),
               let url = String.Links.termsOfUse.url {
                logButtonPressedAnalyticEvents(button: .termsOfUse)
                WebViewController.show(in: self, withURL: url)
            } else if privacyPolicyText.contains(detectedWord),
                      let url = String.Links.privacyPolicy.url {
                logButtonPressedAnalyticEvents(button: .privacyPolicy)
                WebViewController.show(in: self, withURL: url)
            } else {
                didTapCheckboxContainer()
            }
        }
    }
    
    func getWordAtPosition(_ point: CGPoint) -> String? {
        if let textPosition = agreementTextView.closestPosition(to: point) {
            if let range = agreementTextView.tokenizer.rangeEnclosingPosition(textPosition,
                                                                              with: .word,
                                                                              inDirection: UITextDirection(rawValue: 1)) {
                return agreementTextView.text(in: range)
            }
        }
        return nil
    }
}

// MARK: - Setup methods
private extension HappyEndViewController {
    func setup() {
        getStartedButton.isEnabled = false
        localizeContent()
        checkboxContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCheckboxContainer)))
        agreementTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAgreementTextView)))
        
        checkbox.accessibilityIdentifier = "Happy End Agree Checkbox"
        getStartedButton.accessibilityIdentifier = "Happy End Get Started Button"
    }
    
    func localizeContent() {
        titleLabel.setTitle(String.Constants.youAreAllDoneTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.youAreAllDoneSubtitle.localized())
        getStartedButton.setTitle(String.Constants.getStarted.localized(), image: nil)
        
        agreementTextView.isUserInteractionEnabled = true
        agreementTextView.setAttributedTextWith(text: String.Constants.agreeToTUAndPP.localized(),
                                                font: .currentFont(withSize: 14, weight: .medium),
                                                textColor: .foregroundDefault)
        agreementTextView.updateAttributesOf(text: termsOfUseText,
                                             textColor: .foregroundAccent)
        agreementTextView.updateAttributesOf(text: privacyPolicyText,
                                             textColor: .foregroundAccent)
    }
}
