//
//  EnterPasscodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.04.2022.
//

import UIKit


// MARK: - Base class. Shouldn't be used directly. 
class EnterPasscodeViewController: BaseViewController, DigitalKeyboardDelegate, ViewWithDashesProgress {
    
    static let NibName = "EnterPasscodeViewController"
    
    @IBOutlet private(set) weak var titleLabel: UDTitleLabel!
    @IBOutlet private(set) weak var keyboardContainerView: UIView!
    var progress: Double? { nil }
    
    var passwordsNotMatchingErrorMessage: String { "" }
    
    weak var keyboard: DigitalKeyboardViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reset()
    }
    
    // MARK: - DigitalKeyboardDelegate
    func didEnter(passcode: [Character]) { }
  
}

// MARK: - Common methods
extension EnterPasscodeViewController {
    func reset() {
        guard let keyboardVc = self.children.first as? DigitalKeyboardViewController else { return }
        keyboardVc.reset()
    }
    
    func passwordsMatch(_ lhs: [Character], _ rhs: [Character]) -> Bool {
        guard lhs == rhs else {
            Vibration.error.vibrate()
            self.reset()
            showPasscodeNotMatchAlert()
            return false
        }
        Vibration.success.vibrate()
        return true
    }
    
    func storePasscode(_ passcode: [Character]) {
        KeychainPrivateKeyStorage.instance.store(String(passcode),
                                                 for: .passcode)
        
        var settings = User.instance.getSettings()
        settings.touchIdActivated = false
        User.instance.update(settings: settings)
    }
    
    func showPasscodeNotMatchAlert() {
        let alert = UIAlertController(title: passwordsNotMatchingErrorMessage, message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: String.Constants.tryAgain.localized(), style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
    
    func resetWarningLabel() {
        self.keyboard?.resetWarningLabel()
    }
    
    func showWipingMessage() {
        self.keyboard?.setWipingLabel("App data ill be wiped after one more wrong attempt")
    }
    
    func showLockingMessage(sec: Int) {
        self.keyboard?.setWipingLabel("App will be unlocked in \(sec) sec")
    }
}

// MARK: - Setup methods
private extension EnterPasscodeViewController {
    func setup() {
        addProgressDashesView()
        setupUI()
        setupDigitalKeyboard()
    }
    
    func setupUI() {
        keyboardContainerView.clipsToBounds = false
        keyboardContainerView.backgroundColor = .clear
    }
    
    func setupDigitalKeyboard() {
        let keyboard = DigitalKeyboardViewController.instantiate()
        addChildViewController(keyboard, andEmbedToView: keyboardContainerView)
        (keyboard as? DigitalKeyboardViewController)?.delegate = self
        self.keyboard = keyboard as? DigitalKeyboardViewController
    }
}

