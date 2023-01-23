//
//  EnterBackupViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid  on 22.03.2022.
//

import UIKit
import PromiseKit

protocol EnterBackupViewControllerProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    var password: String { get }
    func startEditing()
    func setContinueButtonEnabled(_ isEnabled: Bool)
    func showError(_ error: String)
}

final class EnterBackupViewController: BaseViewController {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private(set) weak var dashesProgressView: DashesProgressView!
    @IBOutlet private weak var udTextField: UDTextFieldV2!
    @IBOutlet private weak var continueButton: MainButton!
    @IBOutlet private weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var hintLabel: UILabel!

    override var isObservingKeyboard: Bool { true }
    var presenter: EnterBackupPresenterProtocol!

    static func instantiate() -> EnterBackupViewController {
        EnterBackupViewController.nibInstance()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        setup()
        presenter.viewDidLoad()
        udTextField.startEditing()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        let newValue = keyboardFrame.height + Constants.distanceFromButtonToKeyboard
        continueButtonBottomConstraint.constant = max(newValue, continueButtonBottomConstraint.constant)
    }
}

// MARK: - EnterBackupViewControllerProtocol
extension EnterBackupViewController: EnterBackupViewControllerProtocol {
    var password: String { udTextField.text }
    
    func startEditing() {
        udTextField.startEditing()
    }
    
    func setContinueButtonEnabled(_ isEnabled: Bool) {
        continueButton.isUserInteractionEnabled = isEnabled
    }
    
    func showError(_ error: String) {
        Vibration.error.vibrate()
        udTextField.setState(.error(text: error))
        hintLabel.isHidden = true
    }
}

// MARK: - UDTextFieldV2Delegate
extension EnterBackupViewController: UDTextFieldV2Delegate {
    func udTextFieldShouldEndEditing(_ udTextField: UDTextFieldV2) -> Bool {
        presenter.isShowingHelp
    }
    
    func didBeginEditing(_ udTextField: UDTextFieldV2) { }
    
    func didChange(_ udTextField: UDTextFieldV2) {
        udTextField.setState(.default)
        hintLabel.isHidden = false
        continueButton.isEnabled = udTextField.text.isValidPassword()
    }
}

// MARK: - Actions
private extension EnterBackupViewController {
    @IBAction func didTapContinueButton(_ sender: MainButton) {
        presenter.didTapContinueButton()
    }
    
    @objc func didTapLearnMore() {
        presenter.didTapLearnMore()
    }
}

// MARK: - Setup methods
private extension EnterBackupViewController {
    func setup() {
        setupTextFields()
        setupUI()
        setupLabels()
    }
    
    func setupTextFields() {
        udTextField.delegate = self
        udTextField.setSecureTextEntry(true)
        // Remove auto-fill toolbar
        udTextField.setTextContentType(.oneTimeCode)
        
        
        udTextField.setPlaceholder(String.Constants.backupPassword.localized())
    }
    
    func setupUI() {
        continueButtonBottomConstraint.constant = 0
        dashesProgressView.setProgress(0.5)
        continueButton.setTitle(String.Constants.continue.localized(), image: nil)
        view.addGradientCoverKeyboardView(aligning: continueButton,
                                          distanceToKeyboard: Constants.distanceFromButtonToKeyboard)
    }
    
    func setupLabels() {
        titleLabel.setTitle(String.Constants.addBackupWalletTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.addBackupWalletSubtitle.localized())

        hintLabel.setAttributedTextWith(text: String.Constants.addBackupWalletHint.localized(), font: .currentFont(withSize: 12, weight: .regular), textColor: .foregroundSecondary)
        hintLabel.updateAttributesOf(text: String.Constants.learnMore.localized(), withFont: .currentFont(withSize: 12, weight: .medium), textColor: .foregroundAccent)
        
        hintLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapLearnMore))
        hintLabel.addGestureRecognizer(tap)
    }
}
