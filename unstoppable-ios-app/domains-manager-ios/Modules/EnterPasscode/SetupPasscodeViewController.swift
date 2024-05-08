//
//  SetupPasscodeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.04.2022.
//

import UIKit

final class SetupPasscodeViewController: EnterPasscodeViewController {
    
    private var mode: Mode!
    private var didCreatePasscode = false
    override var passwordsNotMatchingErrorMessage: String { String.Constants.passcodeDontMatch.localized() }
    override var analyticsName: Analytics.ViewName {
        switch mode {
        case .create, .none:
            return .onboardingCreatePasscode
        case .confirm:
            return .onboardingCreatePasscodeConfirm
        }
    }

    static func instantiate(mode: Mode) -> SetupPasscodeViewController {
        let vc = SetupPasscodeViewController.nibInstance(nibName: EnterPasscodeViewController.NibName)
        vc.mode = mode
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        didCreatePasscode = false
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if case .create(_ , let cancellationCallback) = self.mode,
           !didCreatePasscode {
            cancellationCallback()
        }
    }
 
    override func didEnter(passcode: [Character]) {
        switch mode {
        case .create(let completionCallback, _):
            logAnalytic(event: .didEnterPasscode)
            Vibration.success.vibrate()
            didCreatePasscode(passcode, completionCallback: completionCallback)
        case .confirm(let completionCallback, let passcodeToConfirm):
            logAnalytic(event: .didConfirmPasscode)
            guard passwordsMatch(passcode, passcodeToConfirm) else { return }
            
            didConfirmPasscode(passcode)
            completionCallback()
        case .none:
            return
        }
    }
}

// MARK: - Private methods
private extension SetupPasscodeViewController {
    func didCreatePasscode(_ passcode: [Character], completionCallback: @escaping EmptyCallback) {
        didCreatePasscode = true
        let passVC = SetupPasscodeViewController.instantiate(mode: .confirm(completionCallback: completionCallback, passcode: passcode))
        cNavigationController?.pushViewController(passVC, animated: true)
        navigationController?.pushViewController(passVC, animated: true)
    }
    
    func didConfirmPasscode(_ passcode: [Character]) {
        storePasscode(passcode)
        
        if let nav = cNavigationController,
           // Find first vc who called EnterPasscode.
           let vc = nav.viewControllers.reversed().first(where: { !($0 is EnterPasscodeViewController) }) {
            nav.popToViewController(vc, animated: true)
        } else {
            navigationController?.popViewController(animated: true)
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - Setup methods
private extension SetupPasscodeViewController {
    func setup() {
        setupUI()
    }
    
    func setupUI() {
        dashesProgressView.isHidden = true
        titleLabel.setTitle(mode.title)
    }
}

// MARK: - Mode
extension SetupPasscodeViewController {
    enum Mode {
        case create(completionCallback: EmptyCallback, cancellationCallback: EmptyCallback)
        case confirm(completionCallback: EmptyCallback, passcode: [Character])
        
        var title: String {
            switch self {
            case .create:
                return String.Constants.createNewPasscode.localized()
            case .confirm:
                return String.Constants.confirmNewPasscode.localized()
            }
        }
    }
}

import SwiftUI
struct SetupPasscodeViewControllerWrapper: UIViewControllerRepresentable {
    
    let mode: SetupPasscodeViewController.Mode
    
    func makeUIViewController(context: Context) -> UIViewController {
        SetupPasscodeViewController.instantiate(mode: mode)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
}
