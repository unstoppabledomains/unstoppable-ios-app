//
//  DigitalKeyboardViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.04.2022.
//

import UIKit

protocol DigitalKeyboardDelegate: AnyObject {
    func didEnter(passcode: [Character])
    func getWarningType() -> DigitalKeyboardViewController.WarningType
}

final class DigitalKeyboardViewController: UIViewController {
    
    enum WarningType {
        case none
        case lock
        case wipe
    }
    
    @IBOutlet private weak var passcodeInputView: PasscodeInputView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet private var keyboardButtons: [PasscodeButton]!
    
    weak var delegate: DigitalKeyboardDelegate?
    
    var enabled = true
    var timeCountDown = 60

    static func instantiate() -> UIViewController {
        nibInstance()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
}

// MARK: - Open methods
extension DigitalKeyboardViewController {
    func reset() {
        passcodeInputView.reset()
        resetWarningLabel()
        
        setupWarningLabel()
    }
    
    func setupWarningLabel() {
        guard let warningType = delegate?.getWarningType() else {
            Debugger.printFailure("No delegate for keyboard found")
            return
        }
        switch warningType {
        case .none: resetWarningLabel()
        case .wipe: setWipingLabel(String.Constants.allDataWillBeWiped)
        case .lock: setWaitingLabel(String.Constants.appWillBeUnlocked)
        }
    }
    
    func resetWarningLabel() {
        warningLabel.layer.masksToBounds = true
        warningLabel.layer.cornerRadius = 8
        warningLabel.text = ""
        warningLabel.backgroundColor = .systemBackground
        warningLabel.isHidden = true
    }
    
    func setWaitingLabel(_ nonLocalizedMessage: String) {
        func stepDown() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                warningLabel.text = nonLocalizedMessage.localized(String(timeCountDown - 1))
                timeCountDown -= 1
                if timeCountDown < 1 {
                    resetWarningLabel()
                    enabled = true
                    return
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    stepDown()
                }
            }
        }
        warningLabel.backgroundColor = .systemBackground
        warningLabel.isHidden = false
        
        enabled = false
        timeCountDown = 60
        stepDown()
    }
    
    func setWipingLabel(_ nonLocalizedMessage: String) {
        warningLabel.text = nonLocalizedMessage.localized()
        warningLabel.backgroundColor = .systemRed
        warningLabel.isHidden = false
    }
}

// MARK: - Actions
private extension DigitalKeyboardViewController {
    @IBAction func didTapDigitalButton(_ sender: UIButton) {
        guard enabled else { return }
        
        let tag = sender.tag
        let startingValue = Int(("0" as UnicodeScalar).value)
        guard let uScalar = UnicodeScalar(tag + startingValue) else { return }
        let c = Character(uScalar)
        
        do {
            try passcodeInputView.add(digit: c)
            if passcodeInputView.isFull {
                didEnterPasscode()
            } else {
                Vibration.rigid.vibrate()
            }
        } catch {
            Vibration.error.vibrate()
        }
    }
    
    @IBAction func didTapErase(_ sender: UIButton) {
        guard enabled else { return }
        do {
            try passcodeInputView.removeLast()
            Vibration.rigid.vibrate()
        } catch {
            Vibration.error.vibrate()
        }
    }
}

// MARK: - Private methods
private extension DigitalKeyboardViewController {
    func didEnterPasscode() {
        delegate?.didEnter(passcode: passcodeInputView.code)
    }
}

// MARK: - Setup methods
private extension DigitalKeyboardViewController {
    func setup() {
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .clear
        view.clipsToBounds = false
        
        for button in keyboardButtons {
            let text = button.title(for: .normal) ?? ""
            let title = button.tag == 33 ? "" : text
            let image: UIImage? = button.tag == 33 ? UIImage(named: "deleteKeyboardButton") : nil
            button.setTitle("", for: .normal)
            button.setTitle(title, image: image)
            button.clipsToBounds = false
        }
    }
}
