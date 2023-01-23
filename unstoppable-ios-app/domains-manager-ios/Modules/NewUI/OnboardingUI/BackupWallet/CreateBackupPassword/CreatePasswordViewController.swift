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

final class CreatePasswordViewController: BaseViewController {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private(set) weak var dashesProgressView: DashesProgressView!
    @IBOutlet private weak var backupPasswordTextfield: UDTextFieldV2!
    @IBOutlet private weak var confirmPasswordTextfield: UDTextFieldV2!
    @IBOutlet private weak var createPasswordButton: MainButton!
    @IBOutlet private weak var createPasswordButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var hostScrollView: UIScrollView!

    private var activeField: UDTextFieldV2?
    override var isObservingKeyboard: Bool { true }
    var presenter: CreatePasswordPresenterProtocol!
    
    static func instantiate() -> CreatePasswordViewController {
        CreatePasswordViewController.nibInstance()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        backupPasswordTextfield.startEditing()
        presenter.viewDidLoad()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        let newValue = keyboardFrame.height + Constants.distanceFromButtonToKeyboard
        createPasswordButtonBottomConstraint.constant = max(newValue, createPasswordButtonBottomConstraint.constant)
    }
}

// MARK: - CreatePasswordViewControllerProtocol
extension CreatePasswordViewController: CreatePasswordViewControllerProtocol {
    var password: String { backupPasswordTextfield.text }
    
    func startEditing() {
        (activeField ?? backupPasswordTextfield)?.startEditing()
    }
}

// MARK: - UDTextFieldDelegate
extension CreatePasswordViewController: UDTextFieldV2Delegate {
    func udTextFieldShouldEndEditing(_ udTextField: UDTextFieldV2) -> Bool {
        if udTextField == backupPasswordTextfield {
            return presenter.isShowingHelp || udTextField.text.isValidPassword()
        }
        
        return true
    }
  
    func didChange(_ udTextField: UDTextFieldV2) {
        let input = udTextField.text
        
        let backupPassword = backupPasswordTextfield.text
        let confirmedPassword = confirmPasswordTextfield.text
        let buttonEnabled = backupPassword.isValidPassword()
        && backupPassword == confirmedPassword
        createPasswordButton.isEnabled = buttonEnabled
        
        if udTextField == backupPasswordTextfield {
            if input.isEmpty {
                backupPasswordTextfield.setState(.info(text: String.Constants.passwordRuleAtLeast.localized(), style: .grey))
                setConfirmPasswordTextfieldHidden(true)
                return
            }
            
            if input.count < 8 {
                udTextField.setState(.info(text: String.Constants.passwordRuleCharacters.localized(),
                                           style: .red))
                setConfirmPasswordTextfieldHidden(true)
                return
            }
            
            if !input.hasDecimalDigit {
                udTextField.setState(.info(text: String.Constants.passwordRuleNumber.localized(),
                                           style: .red))
                setConfirmPasswordTextfieldHidden(true)
                return
            }
            
            setConfirmPasswordTextfieldHidden(false)
            udTextField.setState(.info(text: String.Constants.passwordRuleAtLeast.localized(),
                                       style: .green))
        }
    }
    
    func didBeginEditing(_ udTextField: UDTextFieldV2) {
        self.activeField = udTextField
    }
    
    func didTapDoneButton(_ udTextField: UDTextFieldV2) {
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
}

// MARK: - Private methods
private extension CreatePasswordViewController {
    @IBAction func createPasswordButtonPressed(_ sender: UIButton) {
        presenter.createPasswordButtonPressed()
    }
    
    @objc func didTapLearnMore() {
        presenter.didTapLearnMore()
    }
    
    func setConfirmPasswordTextfieldHidden(_ isHidden: Bool) {
        confirmPasswordTextfield.isHidden = confirmPasswordTextfield.text.isEmpty ? isHidden : false
    }
}

// MARK: - Setup methods
private extension CreatePasswordViewController {
    func setup() {
        setupUI()
        setupTextFields()
        setupLabels()
    }
    
    func setupTextFields() {
        backupPasswordTextfield.delegate = self
        confirmPasswordTextfield.delegate = self
        backupPasswordTextfield.setSecureTextEntry(true)
        confirmPasswordTextfield.setSecureTextEntry(true)
        // Remove auto-fill toolbar
        backupPasswordTextfield.setTextContentType(.oneTimeCode)
        confirmPasswordTextfield.setTextContentType(.oneTimeCode)
        confirmPasswordTextfield.isHidden = true
        
        backupPasswordTextfield.setPlaceholder(String.Constants.backupPassword.localized())
        confirmPasswordTextfield.setPlaceholder(String.Constants.confirmPassword.localized())
        
        backupPasswordTextfield.setState(.info(text: String.Constants.passwordRuleAtLeast.localized(), style: .grey))
    }
    
    func setupUI() {
        createPasswordButtonBottomConstraint.constant = 0
        dashesProgressView.setProgress(0.75)
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
