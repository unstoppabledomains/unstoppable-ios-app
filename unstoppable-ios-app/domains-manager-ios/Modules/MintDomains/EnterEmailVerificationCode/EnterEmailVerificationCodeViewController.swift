//
//  EnterEmailVerificationCodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.05.2022.
//

import UIKit

@MainActor
protocol EnterEmailVerificationCodeViewProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    func setWith(email: String)
    func setResendCodeButton(enabled: Bool, secondsLeft: Int?)
    func setInvalidCode()
    func setCode(_ code: String)
    func setLoading(_ isLoading: Bool)
}

@MainActor
final class EnterEmailVerificationCodeViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var openEmailAppButton: SecondaryButton!
    @IBOutlet private weak var resendCodeButton: ResendCodeButton!
    @IBOutlet private weak var codeVerificationView: CodeVerificationView!
    @IBOutlet private weak var openEmailButtonBottomConstraint: NSLayoutConstraint!
    
    var presenter: EnterEmailVerificationCodeViewPresenterProtocol!
    override var isObservingKeyboard: Bool { true }
    override var analyticsName: Analytics.ViewName { .enterEmailVerificationCode }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        codeVerificationView.startEditing()
        presenter.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presenter.viewDidAppear()
        codeVerificationView.startEditing()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        presenter.viewWillDisappear()
        hideKeyboard()
    }
  
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        let newValue = keyboardFrame.height + Constants.distanceFromButtonToKeyboard
        openEmailButtonBottomConstraint.constant = max(newValue, openEmailButtonBottomConstraint.constant)
    }
}

// MARK: - EnterEmailVerificationCodeViewProtocol
extension EnterEmailVerificationCodeViewController: EnterEmailVerificationCodeViewProtocol {
    var progress: Double? { presenter.progress }
    
    func setWith(email: String) {
        subtitleLabel.setSubtitle(String.Constants.enterVerificationCodeSubtitle.localized(email))
        subtitleLabel.updateAttributesOf(text: email,
                                         withFont: .currentFont(withSize: subtitleLabel.font.pointSize, weight: .medium),
                                         textColor: .foregroundDefault)
    }
    
    func setResendCodeButton(enabled: Bool, secondsLeft: Int?) {
        resendCodeButton.isEnabled = enabled
        if let secondsLeft = secondsLeft {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.minute, .second]
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = .pad
            
            let formattedTime = formatter.string(from: TimeInterval(secondsLeft)) ?? ""
            resendCodeButton.setTitle(String.Constants.resendCodeIn.localized(formattedTime), image: nil)
        } else {
            resendCodeButton.setTitle(String.Constants.resendCode.localized(), image: nil)
        }
    }
    
    func setCode(_ code: String) {
        codeVerificationView.code = code 
    }
    
    func setInvalidCode() {
        codeVerificationView.clear()
        codeVerificationView.setInvalid()
        Vibration.error.vibrate()
    }
    
    func setLoading(_ isLoading: Bool) {
        codeVerificationView.setEnabled(!isLoading)
        openEmailAppButton.isHidden = isLoading
        resendCodeButton.isHidden = isLoading
        if isLoading {
            codeVerificationView.stopEditing()
        }
    }
}

// MARK: - Actions
private extension EnterEmailVerificationCodeViewController {
    @IBAction func openEmailButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .openEmailApp)
        presenter.openEmailButtonPressed()
    }
    
    @IBAction func resendCodeButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .resendCode)
        presenter.resendCodeButtonPressed()
    }
}
// MARK: - Private functions
private extension EnterEmailVerificationCodeViewController {

}

// MARK: - Setup functions
private extension EnterEmailVerificationCodeViewController {
    func setup() {
        addProgressDashesView()
        localizeContent()
        setupCodeVerificationView()
    }
    
    func localizeContent() {
        titleLabel.setTitle(String.Constants.enterVerificationCodeTitle.localized())
        openEmailAppButton.setTitle(String.Constants.openEmailApp.localized(), image: nil)
    }
    
    func setupCodeVerificationView() {
        codeVerificationView.setNumberOfCharacters(presenter.numberOfCharactersToVerify)
        codeVerificationView.didEnterCodeCallback = { [weak self] code in
            self?.presenter.didEnterVerificationCode(code)
        }
    }
}
