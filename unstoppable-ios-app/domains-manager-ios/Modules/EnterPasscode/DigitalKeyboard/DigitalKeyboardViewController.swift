//
//  DigitalKeyboardViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.04.2022.
//

import UIKit

protocol DigitalKeyboardDelegate: AnyObject {
    func didEnter(passcode: [Character])
}

final class DigitalKeyboardViewController: UIViewController {
    
    @IBOutlet private weak var passcodeInputView: PasscodeInputView!
    @IBOutlet private var keyboardButtons: [PasscodeButton]!
    
    weak var delegate: DigitalKeyboardDelegate?
    
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
    }
}

// MARK: - Actions
private extension DigitalKeyboardViewController {
    @IBAction func didTapDigitalButton(_ sender: UIButton) {
        
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
