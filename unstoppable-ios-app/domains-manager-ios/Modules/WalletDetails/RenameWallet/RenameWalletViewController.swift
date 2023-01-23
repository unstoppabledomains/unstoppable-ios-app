//
//  RenameWalletViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.05.2022.
//

import UIKit

@MainActor
protocol RenameWalletViewProtocol: BaseViewControllerProtocol {
    func setWalletName(_ name: String)
    func setWalletDisplayInfo(_ walletDisplayInfo: WalletDisplayInfo)
    func setWalletAddress(_ address: String)
    func setDoneButtonEnabled(_ enabled: Bool)
    func setErrorMessage(_ errorMessage: String?)
}

@MainActor
final class RenameWalletViewController: BaseViewController {
    
    @IBOutlet private weak var walletImageView: ResizableRoundedWalletImageView!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var walletAddressLabel: UILabel!
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var doneButton: MainButton!
    @IBOutlet private weak var doneButtonBottomConstraint: NSLayoutConstraint!

    override var isObservingKeyboard: Bool { true }
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .renameWallet }
    override var additionalAppearAnalyticParameters: Analytics.EventParameters { [.wallet : presenter.walletAddress]}
    var presenter: RenameWalletViewPresenterProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
        textField.becomeFirstResponder()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        let newValue = keyboardFrame.height + Constants.distanceFromButtonToKeyboard
        doneButtonBottomConstraint.constant = max(newValue, doneButtonBottomConstraint.constant)
    }
}

// MARK: - RenameWalletViewProtocol
extension RenameWalletViewController: RenameWalletViewProtocol {
    func setWalletName(_ name: String) {
        textField.text = name
    }
    
    func setWalletDisplayInfo(_ walletDisplayInfo: WalletDisplayInfo) {
        walletImageView.setWith(walletInfo: walletDisplayInfo)
    }
    
    func setWalletAddress(_ address: String) {
        walletAddressLabel.setAttributedTextWith(text: address,
                                                 font: .currentFont(withSize: 16, weight: .regular),
                                                 textColor: .foregroundSecondary)
    }
    
    func setDoneButtonEnabled(_ enabled: Bool) {
        doneButton.isEnabled = enabled
    }
    
    func setErrorMessage(_ errorMessage: String?) {
        errorView.isHidden = errorMessage == nil
        if let errorMessage = errorMessage {
            errorLabel.setAttributedTextWith(text: errorMessage,
                                             font: .currentFont(withSize: 16, weight: .medium),
                                             textColor: .foregroundDanger)
        }
    }
}

// MARK: - UITextFieldDelegate
extension RenameWalletViewController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if cNavigationController?.viewControllers.last != self || cNavigationController?.isTransitioning == true || isDisappearing {
            return true
        }
        return false
    }
    
    @objc func textFieldDidEdit(_ textField: UITextField) {
        presenter.nameDidChange(textField.text ?? "")
    }
}

// MARK: - Private functions
private extension RenameWalletViewController {
    @IBAction func doneButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .done)
        presenter.doneButtonPressed()
    }
}

// MARK: - Setup functions
private extension RenameWalletViewController {
    func setup() {
        view.accessibilityIdentifier = "Rename Wallet Screen"
        textField.accessibilityIdentifier = "Rename Wallet Text Field"
        doneButton.accessibilityIdentifier = "Rename Wallet Done Button"
        cNavigationController?.navigationBar.navBarContentView.backButton.accessibilityIdentifier = "Rename Navigation Back Button"
        setupTextField()
        setupErrorView()
        doneButton.setTitle(String.Constants.doneButtonTitle.localized(), image: nil)
    }
    
    func setupTextField() {
        textField.font = .currentFont(withSize: 32, weight: .bold)
        textField.textColor = .foregroundDefault
        textField.textAlignment = .center
        textField.autocapitalizationType = .sentences
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidEdit(_:)), for: .editingChanged)
        let placeholderParagraphStyle = NSMutableParagraphStyle()
        placeholderParagraphStyle.alignment = .center
        textField.attributedPlaceholder = NSAttributedString(string: String.Constants.walletNamePlaceholder.localized(presenter.walletSourceName.lowercased()),
                                                             attributes: [.font: UIFont.currentFont(withSize: 32,
                                                                                                    weight: .bold),
                                                                          .foregroundColor: UIColor.foregroundMuted,
                                                                          .paragraphStyle: placeholderParagraphStyle])
    }
    
    func setupErrorView() {
        errorView.isHidden = true
    }
}
