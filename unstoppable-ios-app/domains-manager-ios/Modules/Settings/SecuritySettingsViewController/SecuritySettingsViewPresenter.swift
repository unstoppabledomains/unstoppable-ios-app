//
//  SecuritySettingsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import Foundation

@MainActor
protocol SecuritySettingsViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: SecuritySettingsViewController.Item)
}

@MainActor
final class SecuritySettingsViewPresenter: ViewAnalyticsLogger {
    private weak var view: SecuritySettingsViewProtocol?
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    
    init(view: SecuritySettingsViewProtocol) {
        self.view = view
    }
}

// MARK: - SecuritySettingsViewPresenterProtocol
extension SecuritySettingsViewPresenter: SecuritySettingsViewPresenterProtocol {
    func viewDidLoad() {
        resolveAuthState()
    }
    
    func didSelectItem(_ item: SecuritySettingsViewController.Item) {
        switch item {
        case .authentication(let type):
            logButtonPressedAnalyticEvents(button: type.analyticsName)
            changeAuthType(type)
        case .action(let action):
            logButtonPressedAnalyticEvents(button: .changePasscode)
            handleAction(action)
        case .openingTheApp:
            return
        }
    }
}

// MARK: - Private functions
private extension SecuritySettingsViewPresenter {
    func resolveAuthState() {
        Task {
            let authHelper = appContext.authentificationService
            let settings = User.instance.getSettings()
            let isBiometricOn = settings.touchIdActivated
            var snapshot = SecuritySettingsSnapshot()
            
            snapshot.appendSections([.securityType])
            if authHelper.biometryState() != .notAvailable {
                snapshot.appendItems([.authentication(type: .biometric(isOn: isBiometricOn))])
            }
            snapshot.appendItems([.authentication(type: .passcode(isOn: !isBiometricOn))])
            
            if !isBiometricOn {
                snapshot.appendSections([.changePasscode])
                snapshot.appendItems([.action(.changePasscode)])
            }
            
            snapshot.appendSections([.openingAppSettings])
            snapshot.appendItems([.openingTheApp(configuration: .init(isOn: settings.shouldRequireSAOnAppOpening,
                                                                      valueChangedCallback: { [weak self] isOn in
                self?.setRequireSAOnAppOpening(isOn: isOn)
            }))])
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
    
    func changeAuthType(_ type: SecuritySettingsViewController.AuthenticationType) {
        switch type {
        case .biometric(let isOn):
            guard !isOn else { return }

            verifyAuthAndSetBiometricEnabled(true)
        case .passcode(let isOn):
            guard !isOn else { return }
            
            verifyAuthAndSetBiometricEnabled(false)
        }
    }
    
    func verifyAuthAndSetBiometricEnabled(_ isEnabled: Bool) {
        guard let view = self.view else { return }
        
        appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm, completionCallback: { [weak self] in
            DispatchQueue.main.async {
                self?.setBiometricEnabled(isEnabled)
            }
        }(), cancellationCallback: { })
    }
    
    func setBiometricEnabled(_ isEnabled: Bool) {
        guard let view = self.view else { return }

        if isEnabled {
            appContext.authentificationService.authenticateWithBiometricWith(uiHandler: view) { [weak self] result in
                if result == true {
                    self?.logAnalytic(event: .biometricAuthSuccess)
                } else {
                    self?.logAnalytic(event: .biometricAuthFailed)
                }

                DispatchQueue.main.async {
                    self?.setSettingsBiometricEnabled(result == true)
                }
            }
        } else {
            /// Need to give time for blur view disappear. Otherwise it will stuck forever and be visible if user navigate back.
            DispatchQueue.main.asyncAfter(deadline: .now() + appContext.authentificationService.biometricUIProcessingTime) { [weak self] in
                self?.setupPasscode {
                    self?.setSettingsBiometricEnabled(false)
                }
            }
        }
    }
    
    func setupPasscode(completion: EmptyCallback? = nil) {
        let createPasscodeVC = SetupPasscodeViewController.instantiate(mode: .create(completionCallback: { completion?() }, cancellationCallback: { }))
        view?.cNavigationController?.pushViewController(createPasscodeVC, animated: true)
    }
    
    func setSettingsBiometricEnabled(_ isEnabled: Bool) {
        var settings = User.instance.getSettings()
        settings.touchIdActivated = isEnabled
        User.instance.update(settings: settings)
        resolveAuthState()
    }
    
    func handleAction(_ action: SecuritySettingsViewController.Action) {
        switch action {
        case .changePasscode:
            guard let view = self.view else { return }
            
            appContext.authentificationService.verifyWith(uiHandler: view, purpose: .enterOld, completionCallback: { [weak self] in
                self?.setupPasscode()
            }(), cancellationCallback: nil)
        }
    }
    
    func setRequireSAOnAppOpening(isOn: Bool) {
        guard let view = self.view else { return }

        logButtonPressedAnalyticEvents(button: .securitySettingsRequireSAWhenOpen, parameters: [.isOn: String(isOn)])
        Task {
            do {
                if !isOn {
                    try await appContext.authentificationService.verifyWith(uiHandler: view,
                                                                            purpose: .confirm)
                }
                var settings = User.instance.getSettings()
                settings.requireSAOnAppOpening = isOn
                User.instance.update(settings: settings)
            } catch {
                resolveAuthState()
            }
        }
    }
}
