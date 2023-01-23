//
//  AddWalletViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 22.03.2022.
//

import UIKit

@MainActor
protocol AddWalletViewControllerProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    var input: String { get }
    
    func setInput(_ input: String)
    func setHint(_ hint: String)
    func setInputState(_ state: UDTextView.State)
    func setContinueButtonEnabled(_ isEnabled: Bool)
    func setPasteButtonHidden(_ isHidden: Bool)
    func startEditing()
    func setWith(externalWalletIcon: UIImage, address: String)
}

final class AddWalletViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var udTextView: UDTextView!
    @IBOutlet private weak var pasteButton: TextButton!
    @IBOutlet private weak var continueButton: MainButton!
    @IBOutlet private weak var continuePasswordButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var blurCoverView: UIVisualEffectView!
    @IBOutlet private weak var badgeView: GenericBadgeView!
    
    
    var presenter: AddWalletPresenterProtocol!
    override var navBackStyle: NavBackIconStyle { presenter.navBackStyle }
    override var isObservingKeyboard: Bool { true }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
        DispatchQueue.main.async { [weak self] in
            self?.udTextView.startEditing()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if cNavigationController?.topViewController == self {
            udTextView.startEditing()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        hideKeyboard()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        continuePasswordButtonBottomConstraint.constant = keyboardHeight + Constants.distanceFromButtonToKeyboard
        let options = UIView.AnimationOptions(rawValue: UInt(curve))
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - AddWalletViewControllerProtocol
extension AddWalletViewController: AddWalletViewControllerProtocol {
    var progress: Double? { presenter.progress }
    var input: String { udTextView.text }
    
    func setInput(_ input: String) {
        self.udTextView.setText(input)
    }
    
    func setHint(_ hint: String) {
        udTextView.setPlaceholder(" " + hint)
    }
    
    func setInputState(_ state: UDTextView.State) {
        udTextView.setState(state)
    }
    
    func setContinueButtonEnabled(_ isEnabled: Bool) {
        continueButton.isEnabled = isEnabled
    }
    
    func setPasteButtonHidden(_ isHidden: Bool) {
        pasteButton.isHidden = isHidden
    }
    
    func startEditing() {
        udTextView.startEditing()
    }
    
    func setWith(externalWalletIcon: UIImage, address: String) {
        badgeView.setWith(externalWalletIcon: externalWalletIcon, address: address)
        badgeView.isHidden = false
    }
}

// MARK: - UDTextViewDelegate
extension AddWalletViewController: UDTextViewDelegate {
    func udTextViewShouldEndEditing(_ udTextView: UDTextView) -> Bool {
        cNavigationController?.viewControllers.last != self || cNavigationController?.isTransitioning == true || isDisappearing
    }
    
    func didChange(_ udTextView: UDTextView) {
        presenter.didChangeInput()
    }
}

// MARK: - Actions
private extension AddWalletViewController {
    @IBAction func didTapContinueButton(_ sender: MainButton) {
        logButtonPressedAnalyticEvents(button: .continue)
        presenter.didTapContinueButton()
    }
    
    @IBAction func didTapPasteButton(_ sender: MainButton) {
        logButtonPressedAnalyticEvents(button: .pasteFromClipboard)
        presenter.didTapPasteButton()
    }
    
    @objc func screenCapturedDidChange() {
        setProtectionBlurCover(hidden: !UIScreen.main.isCaptured)
    }
}

// MARK: - Setup methods
private extension AddWalletViewController {
    func setup() {
        addProgressDashesView()
        setupUI()
        setupTextView()
        setupScreenRecordingProtection()
        badgeView.isHidden = true
    }
    
    func setupUI() {
        continuePasswordButtonBottomConstraint.constant = Constants.distanceFromButtonToKeyboard
        titleLabel.setTitle(String.Constants.addWalletTitle.localized())
        continueButton.setTitle(String.Constants.continue.localized(), image: nil)
        view.addGradientCoverKeyboardView(aligning: continueButton,
                                          distanceToKeyboard: Constants.distanceFromButtonToKeyboard)
        pasteButton.setAttributedTextWith(text: String.Constants.paste.localized(),
                                          font: .currentFont(withSize: 16, weight: .medium),
                                          textColor: .foregroundAccent,
                                          lineHeight: 24)
    }
    
    func setupTextView() {
        udTextView.delegate = self
        udTextView.setHeader(String.Constants.addWalletTitle.localized())
        udTextView.setAutolayoutStyle(.fixedTextHeight(132))
        udTextView.setCapitalisation(.none)
        udTextView.setAutocorrectionType(.no)
        udTextView.setSpellCheckingType(.no)
    }
    
    func setupScreenRecordingProtection() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(screenCapturedDidChange),
                                               name: UIScreen.capturedDidChangeNotification,
                                               object: nil)
        screenCapturedDidChange()
    }
    
    func setProtectionBlurCover(hidden: Bool) {
        blurCoverView.isHidden = hidden
    }
}
