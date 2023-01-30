//
//  CreatePasswordViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 25.03.2022.
//

import UIKit

protocol CreatePasswordViewControllerProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    var password: String { get }
    func startEditing()
}

final class CreatePasswordViewController: BaseViewController, WalletDataValidator {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var backupPasswordTextfield: UDTextField!
    @IBOutlet private weak var confirmPasswordTextfield: UDTextField!
    @IBOutlet private weak var createPasswordButton: MainButton!
    @IBOutlet private weak var createPasswordButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var hostScrollView: UIScrollView!

    private var activeField: UDTextField?
    override var isObservingKeyboard: Bool { true }
    var presenter: CreateBackupPasswordPresenterProtocol!
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }

    static func instantiate() -> CreatePasswordViewController {
        CreatePasswordViewController.nibInstance()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
        backupPasswordTextfield.startEditing()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if cNavigationController?.topViewController == self {
            backupPasswordTextfield.startEditing()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        hideKeyboard()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        let newValue = keyboardFrame.height + Constants.distanceFromButtonToKeyboard
        createPasswordButtonBottomConstraint.constant = max(newValue, createPasswordButtonBottomConstraint.constant)
        let options = UIView.AnimationOptions(rawValue: UInt(curve))
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - CreatePasswordViewControllerProtocol
extension CreatePasswordViewController: CreatePasswordViewControllerProtocol {
    var progress: Double? { presenter.progress }
    var password: String { backupPasswordTextfield.text }
    
    func startEditing() {
        (activeField ?? backupPasswordTextfield)?.startEditing()
    }
}

// MARK: - UDTextFieldDelegate
extension CreatePasswordViewController: UDTextFieldV2Delegate {
    func udTextFieldShouldEndEditing(_ udTextField: UDTextField) -> Bool {
        if cNavigationController?.viewControllers.last != self || cNavigationController?.isTransitioning == true || isDisappearing {
            return true
        }
        if udTextField == backupPasswordTextfield {
            return presenter.isShowingHelp || udTextField.text.isValidPassword()
        }
        
        return true
    }
  
    func didChangeText(_ udTextField: UDTextField) {
        let input = udTextField.text
        
        let backupPassword = backupPasswordTextfield.text
        let confirmedPassword = confirmPasswordTextfield.text
        let buttonEnabled = backupPassword.isValidPassword() && backupPassword == confirmedPassword
        createPasswordButton.isEnabled = buttonEnabled
        
        if udTextField == backupPasswordTextfield {
            switch isBackupPasswordValid(input) {
            case .success:
                setConfirmPasswordTextfieldHidden(false)
                udTextField.setState(.info(text: String.Constants.passwordRuleAtLeast.localized(),
                                           style: .green))
            case .failure(let error):
                udTextField.setState(.info(text: error.message,
                                           style: error == .empty ? .grey : .red))
                setConfirmPasswordTextfieldHidden(true)
            }
        } else {
            if !confirmedPassword.isEmpty && confirmedPassword != backupPassword {
                udTextField.setState(.info(text: String.Constants.passwordRuleMatch.localized(),
                                           style: .red))
            } else {
                udTextField.setState(.default)
            }
        }
    }
    
    func didBeginEditing(_ udTextField: UDTextField) {
        self.activeField = udTextField
    }
    
    func didTapDoneButton(_ udTextField: UDTextField) {
        func returnResponder() {
            DispatchQueue.main.async {
                udTextField.startEditing()
            }
        }
        
        if udTextField == backupPasswordTextfield,
           udTextField.text.isValidPassword() {
            confirmPasswordTextfield.startEditing()
        } else if udTextField == confirmPasswordTextfield,
                  createPasswordButton.isEnabled {
            createPasswordButtonPressed(createPasswordButton)
            returnResponder()
        } else {
            returnResponder()
        }
    }
    
    func didTapEyeButton(_ udTextField: UDTextField, isSecureTextEntry: Bool) {
        logButtonPressedAnalyticEvents(button: isSecureTextEntry ? .hidePassword : .showPassword,
                                       parameters: [.textField : udTextField == backupPasswordTextfield ? "enterPassword" : "verifyPassword"])
    }
}

// MARK: - Private methods
private extension CreatePasswordViewController {
    @IBAction func createPasswordButtonPressed(_ sender: UIButton) {
        logButtonPressedAnalyticEvents(button: .continue)
        presenter.createPasswordButtonPressed()
    }
    
    @objc func didTapLearnMore() {
        logButtonPressedAnalyticEvents(button: .learnMore)
        presenter.didTapLearnMore()
    }
    
    func setConfirmPasswordTextfieldHidden(_ isHidden: Bool) {
        let isFieldHidden = confirmPasswordTextfield.text.isEmpty ? isHidden : false
        guard isFieldHidden != confirmPasswordTextfield.isHidden else { return }
        
        if confirmPasswordTextfield.isHidden,
           !isFieldHidden {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self]  in
                guard let scrollView = self?.hostScrollView else { return }
                
                if scrollView.contentSize.height > scrollView.bounds.height {
                    let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom)
                    scrollView.setContentOffset(bottomOffset, animated: true)
                }
            }
        }
        confirmPasswordTextfield.isHidden = isFieldHidden
    }
}

// MARK: - Setup methods
private extension CreatePasswordViewController {
    func setup() {
        addProgressDashesView()
        setupUI()
        setupTextFields()
        setupLabels()
        
        backupPasswordTextfield.setTextFieldAccessibilityIdentifier("Create Back Up Password Enter Text Field")
        confirmPasswordTextfield.setTextFieldAccessibilityIdentifier("Create Back Up Password Repeat Text Field")
        createPasswordButton.accessibilityIdentifier = "Create Back Up Password Done Button"
    }
    
    func setupTextFields() {
        backupPasswordTextfield.delegate = self
        confirmPasswordTextfield.delegate = self
        backupPasswordTextfield.setSecureTextEntry(true)
        confirmPasswordTextfield.setSecureTextEntry(true)
        backupPasswordTextfield.setAutocorrectionType(.no)
        confirmPasswordTextfield.setAutocorrectionType(.no)
        backupPasswordTextfield.setTextContentType(.oneTimeCode)
        confirmPasswordTextfield.setTextContentType(.oneTimeCode)

        confirmPasswordTextfield.isHidden = true
        
        backupPasswordTextfield.setPlaceholder(String.Constants.backupPassword.localized())
        confirmPasswordTextfield.setPlaceholder(String.Constants.confirmPassword.localized())
        
        backupPasswordTextfield.setState(.info(text: String.Constants.passwordRuleAtLeast.localized(), style: .grey))
    }
    
    func setupUI() {
        createPasswordButtonBottomConstraint.constant = Constants.distanceFromButtonToKeyboard
        createPasswordButton.setTitle(String.Constants.createPassword.localized(), image: nil)
        view.addGradientCoverKeyboardView(aligning: createPasswordButton,
                                          distanceToKeyboard: Constants.distanceFromButtonToKeyboard)
    }
    
    func setupLabels() {
        titleLabel.setTitle(String.Constants.createPassword.localized())
        
        subtitleLabel.setSubtitle(String.Constants.createPasswordDescription.localized())
        let fontSize = subtitleLabel.font.pointSize
        subtitleLabel.updateAttributesOf(text: String.Constants.createPasswordDescriptionHighlighted.localized(), withFont: .currentFont(withSize: fontSize, weight: .medium), textColor: .foregroundDefault)
        subtitleLabel.updateAttributesOf(text: String.Constants.learnMore.localized(), withFont: .currentFont(withSize: fontSize, weight: .medium), textColor: .foregroundAccent)
        
        subtitleLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapLearnMore))
        subtitleLabel.addGestureRecognizer(tap)
    }
}
