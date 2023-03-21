//
//  LoginWithEmailViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2023.
//

import UIKit

@MainActor
protocol LoginWithEmailViewProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    func setLoadingIndicator(active: Bool)
    func setPasswordIsIncorrect()
}

@MainActor
final class LoginWithEmailViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var emailTextfield: UDTextField!
    @IBOutlet private weak var passwordTextfield: UDTextField!
    @IBOutlet private weak var confirmButton: MainButton!
    @IBOutlet private weak var confirmButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var hostScrollView: UIScrollView!
    
    var presenter: LoginWithEmailViewPresenterProtocol!
    override var isObservingKeyboard: Bool { true }
    override var analyticsName: Analytics.ViewName { .loginWithEmailAndPassword }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
        emailTextfield.startEditing()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if cNavigationController?.topViewController == self {
            emailTextfield.startEditing()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        hideKeyboard()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        let newValue = keyboardFrame.height + Constants.distanceFromButtonToKeyboard
        confirmButtonBottomConstraint.constant = max(newValue, confirmButtonBottomConstraint.constant)
        let options = UIView.AnimationOptions(rawValue: UInt(curve))
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - LoginWithEmailViewProtocol
extension LoginWithEmailViewController: LoginWithEmailViewProtocol {
    var progress: Double? { presenter.progress }

    func setLoadingIndicator(active: Bool) {
        confirmButton.isUserInteractionEnabled = !active
        if active {
            confirmButton.showLoadingIndicator()
        } else {
            confirmButton.hideLoadingIndicator()
        }
    }
    
    func setPasswordIsIncorrect() {
        passwordTextfield.setState(.info(text: "Incorrect password or email",
                                         style: .red))
    }
}

// MARK: - UDTextFieldDelegate
extension LoginWithEmailViewController: UDTextFieldV2Delegate {
    func udTextFieldShouldEndEditing(_ udTextField: UDTextField) -> Bool {
        if cNavigationController?.viewControllers.last != self || cNavigationController?.isTransitioning == true || isDisappearing {
            return true
        }
        if udTextField == emailTextfield {
            return udTextField.text.isValidEmail()
        }
        
        return true
    }
    
    func didChangeText(_ udTextField: UDTextField) {
        let input = udTextField.text
        
        let email = emailTextfield.text
        let password = passwordTextfield.text
        let buttonEnabled = email.isValidEmail() && !password.isEmpty
        confirmButton.isEnabled = buttonEnabled
        
        if udTextField == emailTextfield {
            if input.isValidEmail() {
                udTextField.setState(.default)
            } else {
                udTextField.setState(.info(text: "Incorrect email",
                                           style: .red))
            }
        } else {
            udTextField.setState(.default)
        }
    }
    
    func didTapDoneButton(_ udTextField: UDTextField) {
        func returnResponder() {
            DispatchQueue.main.async {
                udTextField.startEditing()
            }
        }
        
        if udTextField == emailTextfield,
           udTextField.text.isValidEmail() {
            passwordTextfield.startEditing()
        } else if udTextField == passwordTextfield,
                  confirmButton.isEnabled {
            confirmButtonPressed(confirmButton)
            returnResponder()
        } else {
            returnResponder()
        }
    }
    
    func didTapEyeButton(_ udTextField: UDTextField, isSecureTextEntry: Bool) {
        logButtonPressedAnalyticEvents(button: isSecureTextEntry ? .hidePassword : .showPassword,
                                       parameters: [.textField : "password"])
    }
}


// MARK: - UIScrollViewDelegate
extension LoginWithEmailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - Private functions
private extension LoginWithEmailViewController {
    @IBAction func confirmButtonPressed(_ sender: UIButton) {
        logButtonPressedAnalyticEvents(button: .confirm)
        presenter.confirmButtonPressed(email: emailTextfield.text, password: passwordTextfield.text)
    }
}

// MARK: - Setup functions
private extension LoginWithEmailViewController {
    func setup() {
        addProgressDashesView()
        setupUI()
        setupTextFields()
        setupLabels()
        hostScrollView.delegate = self
    }
    
    func setupTextFields() {
        emailTextfield.delegate = self
        emailTextfield.setTextContentType(.username)
        emailTextfield.setKeyboardType(.emailAddress)
        passwordTextfield.delegate = self
        passwordTextfield.setSecureTextEntry(true)
        passwordTextfield.setAutocorrectionType(.no)
        passwordTextfield.setTextContentType(.password)
                
        emailTextfield.setPlaceholder(String.Constants.email.localized())
        passwordTextfield.setPlaceholder(String.Constants.password.localized())
    }
    
    func setupUI() {
        confirmButtonBottomConstraint.constant = Constants.distanceFromButtonToKeyboard
        confirmButton.setTitle(String.Constants.confirm.localized(), image: nil)
        view.addGradientCoverKeyboardView(aligning: confirmButton,
                                          distanceToKeyboard: Constants.distanceFromButtonToKeyboard)
    }
    
    func setupLabels() {
        titleLabel.setTitle(String.Constants.loginWithEmailTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.loginWithEmailSubtitle.localized())
    }
}
