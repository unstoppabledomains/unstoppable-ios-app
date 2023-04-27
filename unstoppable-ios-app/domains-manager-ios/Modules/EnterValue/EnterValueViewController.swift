//
//  EnterValueViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import UIKit

@MainActor
protocol EnterValueViewProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    func set(title: String, icon: UIImage?, tintColor: UIColor?)
    func setPlaceholder(_ placeholder: String, style: UDTextField.PlaceholderStyle)
    func setTextFieldRightViewType(_ rightViewType: UDTextField.RightViewType)
    func setValue(_ value: String)
    func setContinueButtonEnabled(_ isEnabled: Bool)
    func setKeyboardType(_ keyboardType: UIKeyboardType)
    func showError(_ error: String?)
    func highlightValue(_ value: String)
}

@MainActor
final class EnterValueViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var udTextField: UDTextField!
    @IBOutlet private weak var continueButton: MainButton!
    @IBOutlet private weak var continueButtonBottomConstraint: NSLayoutConstraint!
    
    override var isObservingKeyboard: Bool { true }
    override var navBackStyle: NavBackIconStyle { presenter.navBackStyle }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    var presenter: EnterValueViewPresenterProtocol!

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

// MARK: - EnterValueViewProtocol
extension EnterValueViewController: EnterValueViewProtocol {
    var progress: Double? { presenter.progress }

    func set(title: String, icon: UIImage?, tintColor: UIColor?) {
        titleLabel.setTitle(title)
        iconImageView.image = icon
        iconImageView.tintColor = tintColor ?? .foregroundMuted
        iconImageView.isHidden = icon == nil
    }
    
    func setPlaceholder(_ placeholder: String, style: UDTextField.PlaceholderStyle) {
        udTextField.setPlaceholderStyle(style)
        udTextField.setPlaceholder(placeholder)
    }
    
    func setTextFieldRightViewType(_ rightViewType: UDTextField.RightViewType) {
        udTextField.setRightViewType(rightViewType)
    }
    
    func setValue(_ value: String) {
        udTextField.setText(value)
        updateClearButton()
    }
    
    func highlightValue(_ value: String) {
        udTextField.highlightText(value, withColor: .foregroundSecondary)
    }
    
    func setContinueButtonEnabled(_ isEnabled: Bool) {
        continueButton.isEnabled = isEnabled
    }
    
    func setKeyboardType(_ keyboardType: UIKeyboardType) {
        udTextField.setKeyboardType(keyboardType)
    }
    
    func showError(_ error: String?) {
        if let error {
            udTextField.setState(.error(text: error))
        } else {
            udTextField.setState(.default)
        }
    }
}

// MARK: - UDTextFieldV2Delegate
extension EnterValueViewController: UDTextFieldV2Delegate {
    func udTextFieldShouldEndEditing(_ udTextField: UDTextField) -> Bool {
        if cNavigationController?.viewControllers.last != self || cNavigationController?.isTransitioning == true || isDisappearing {
            return true
        }
        return false
    }
    
    func didBeginEditing(_ udTextField: UDTextField) { }
    
    func didChangeText(_ udTextField: UDTextField) {
        presenter.valueDidChange(udTextField.text)
        updateClearButton()
    }
}

// MARK: - Actions
private extension EnterValueViewController {
    @IBAction func didTapContinueButton(_ sender: MainButton) {
        logButtonPressedAnalyticEvents(button: .confirm)
        presenter.didTapContinueButton()
    }
}

// MARK: - Private functions
private extension EnterValueViewController {
    func updateClearButton() {
        if udTextField.text.isEmpty {
            udTextField.setRightViewMode(.never)
        } else {
            udTextField.setRightViewMode(.always)
        }
    }
}

// MARK: - Setup functions
private extension EnterValueViewController {
    func setup() {
        addProgressDashesView()
        setupTextFields()
        setupUI()
        setupLabels()
        updateClearButton()
    }
    
    func setupTextFields() {
        udTextField.delegate = self
        udTextField.setAutocorrectionType(.no)
        udTextField.setRightViewMode(.always)
    }
    
    func setupUI() {
        continueButtonBottomConstraint.constant = Constants.distanceFromButtonToKeyboard
        continueButton.setTitle(String.Constants.confirm.localized(), image: nil)
        view.addGradientCoverKeyboardView(aligning: continueButton,
                                          distanceToKeyboard: Constants.distanceFromButtonToKeyboard)
    }
    
    func setupLabels() {
        titleLabel.setTitle(String.Constants.addBackupWalletTitle.localized())
    }
}
