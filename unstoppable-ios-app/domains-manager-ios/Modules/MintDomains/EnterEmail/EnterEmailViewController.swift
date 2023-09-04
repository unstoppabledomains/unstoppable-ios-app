//
//  EnterEmailViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.05.2022.
//

import UIKit

@MainActor
protocol EnterEmailViewProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    var email: String { get }
    func setLoadingIndicator(active: Bool)
    func setEmail(_ email: String)
}

@MainActor
final class EnterEmailViewController: BaseViewController, UserDataValidator {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var emailTF: UDTextField!
    @IBOutlet private weak var continueButton: MainButton!
    @IBOutlet private weak var continueButtonBottomConstraint: NSLayoutConstraint!

    var presenter: EnterEmailViewPresenterProtocol!
    override var isObservingKeyboard: Bool { true }
    override var analyticsName: Analytics.ViewName { .enterEmail }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
        emailTF.startEditing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        emailTF.startEditing()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.hideKeyboard()
    }
    
    override func keyboardDidAdjustFrame(keyboardHeight: CGFloat) {
        let newValue = keyboardFrame.height + Constants.distanceFromButtonToKeyboard
        continueButtonBottomConstraint.constant = newValue
        view.layoutIfNeeded()
    }
}

// MARK: - EnterEmailViewProtocol
extension EnterEmailViewController: EnterEmailViewProtocol {
    var progress: Double? { presenter.progress }
    
    var email: String { emailTF.text.trimmedSpaces }
    
    func setLoadingIndicator(active: Bool) {
        continueButton.isUserInteractionEnabled = !active
        if active {
            continueButton.showLoadingIndicator()
        } else {
            continueButton.hideLoadingIndicator()
        }
    }
    
    func setEmail(_ email: String) {
        emailTF.setText(email)
    }
}

// MARK: - UDTextFieldDelegate
extension EnterEmailViewController: UDTextFieldV2Delegate {
    func udTextFieldShouldEndEditing(_ udTextField: UDTextField) -> Bool {
        if cNavigationController?.viewControllers.last != self || cNavigationController?.isTransitioning == true || cNavigationController?.cNavigationController?.isTransitioning == true {
            return true
        }
        return false
    }
    
    func didChangeText(_ udTextField: UDTextField) {
        let email = udTextField.text.trimmedSpaces
        
        switch isEmailValid(email) {
        case .success:
            continueButton.isEnabled = true
        case .failure:
            continueButton.isEnabled = false
        }
    }
   
}

// MARK: - Private functions
private extension EnterEmailViewController {
    @IBAction func continueButtonPressed() {
        logButtonPressedAnalyticEvents(button: .continue)
        presenter.continueButtonPressed()
    }
}

// MARK: - Setup functions
private extension EnterEmailViewController {
    func setup() {
        addProgressDashesView()
        continueButton.isEnabled = false
        localizeContent()
        setupTextField()
        continueButtonBottomConstraint.constant = Constants.distanceFromButtonToKeyboard
    }
    
    func localizeContent() {
        titleLabel.setTitle(String.Constants.enterEmailTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.enterEmailSubtitle.localized())
        continueButton.setTitle(String.Constants.continue.localized(), image: nil)
    }
    
    func setupTextField() {
        emailTF.delegate = self
        emailTF.setSecureTextEntry(false)
        emailTF.setTextContentType(.emailAddress)
        emailTF.setKeyboardType(.emailAddress)
        emailTF.setAutocorrectionType(.no)
        emailTF.setPlaceholder(String.Constants.email.localized())
    }
}
