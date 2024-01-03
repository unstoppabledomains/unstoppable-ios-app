//
//  EnterBackupViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid  on 22.03.2022.
//

import UIKit

@MainActor
protocol EnterBackupViewControllerProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    var password: String { get }
    func setTitle(_ title: String)
    func setSubtitle(_ subtitle: String)
    func startEditing()
    func setContinueButtonEnabled(_ isEnabled: Bool)
    func showError(_ error: String)
}

@MainActor
final class EnterBackupViewController: BaseViewController, WalletDataValidator {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var udTextField: UDTextField!
    @IBOutlet private weak var continueButton: MainButton!
    @IBOutlet private weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var hintLabel: UILabel!

    override var isObservingKeyboard: Bool { true }
    override var navBackStyle: NavBackIconStyle { presenter.navBackStyle }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if cNavigationController?.topViewController == self {
            udTextField.startEditing()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        hideKeyboard()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        let newValue = keyboardFrame.height + Constants.distanceFromButtonToKeyboard
        continueButtonBottomConstraint.constant = max(newValue, continueButtonBottomConstraint.constant)
        let options = UIView.AnimationOptions(rawValue: UInt(curve))
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - EnterBackupViewControllerProtocol
extension EnterBackupViewController: EnterBackupViewControllerProtocol {
    var progress: Double? { presenter.progress }
    var password: String { udTextField.text }
    
    func setTitle(_ title: String) {
        titleLabel.setTitle(title)
    }
    
    func setSubtitle(_ subtitle: String) {
        subtitleLabel.setSubtitle(subtitle)
    }
    
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
    func udTextFieldShouldEndEditing(_ udTextField: UDTextField) -> Bool {
        if cNavigationController?.viewControllers.last != self || cNavigationController?.isTransitioning == true || isDisappearing {
            return true
        }
        return presenter.isShowingHelp
    }
    
    func didBeginEditing(_ udTextField: UDTextField) { }
    
    func didChangeText(_ udTextField: UDTextField) {
        udTextField.setState(.default)
        hintLabel.isHidden = false
        switch isBackupPasswordValid(udTextField.text) {
        case .success:
            continueButton.isEnabled = true
        case .failure:
            continueButton.isEnabled = false
        }
    }
    
    func didTapEyeButton(_ udTextField: UDTextField, isSecureTextEntry: Bool) {
        logButtonPressedAnalyticEvents(button: isSecureTextEntry ? .hidePassword : .showPassword)
    }
}

// MARK: - Actions
private extension EnterBackupViewController {
    @IBAction func didTapContinueButton(_ sender: MainButton) {
        logButtonPressedAnalyticEvents(button: .continue)
        presenter.didTapContinueButton()
    }
    
    @objc func didTapLearnMore() {
        logButtonPressedAnalyticEvents(button: .learnMore)
        presenter.didTapLearnMore()
    }
}

// MARK: - Setup methods
private extension EnterBackupViewController {
    func setup() {
        addProgressDashesView()
        setupTextFields()
        setupUI()
        setupLabels()
    }
    
    func setupTextFields() {
        udTextField.delegate = self
        udTextField.setSecureTextEntry(true)
        udTextField.setTextContentType(.oneTimeCode)
        udTextField.setAutocorrectionType(.no)
        udTextField.setPlaceholder(String.Constants.backupPassword.localized())
    }
    
    func setupUI() {
        continueButtonBottomConstraint.constant = Constants.distanceFromButtonToKeyboard
        continueButton.setTitle(String.Constants.continue.localized(), image: nil)
        view.addGradientCoverKeyboardView(aligning: continueButton,
                                          distanceToKeyboard: Constants.distanceFromButtonToKeyboard)
    }
    
    func setupLabels() {
        titleLabel.setTitle(String.Constants.addBackupWalletTitle.localized())
        hintLabel.setAttributedTextWith(text: String.Constants.addBackupWalletHint.localized(), font: .currentFont(withSize: 12, weight: .regular), textColor: .foregroundSecondary)
        hintLabel.updateAttributesOf(text: String.Constants.learnMore.localized(), withFont: .currentFont(withSize: 12, weight: .medium), textColor: .foregroundAccent)
        
        hintLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapLearnMore))
        hintLabel.addGestureRecognizer(tap)
    }
}
