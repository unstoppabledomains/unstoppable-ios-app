//
//  SecuritySettingsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.05.2024.
//

import SwiftUI

struct SecuritySettingsView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject private var tabRouter: HomeTabRouter

    var analyticsName: Analytics.ViewName { .securitySettings }
    
    @State private var id = UUID()
    @State private var shouldRequireSAOnAppOpening = User.instance.getSettings().shouldRequireSAOnAppOpening
    
    var body: some View {
        contentView()
            .navigationTitle(String.Constants.settingsSecurity.localized())
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: shouldRequireSAOnAppOpening) { newValue in
                setRequireSAOnAppOpening(isOn: shouldRequireSAOnAppOpening)
            }
            .id(id)
    }
}

// MARK: - Private methods
private extension SecuritySettingsView {
    @ViewBuilder
    func contentView() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                authTypesSection()
                actionsSection()
                securitySettingsSection()
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func authTypesSection() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(spacing: 0) {
                if appContext.authentificationService.biometryState() != .notAvailable {
                    listItemFor(authType: .biometric)
                }
                listItemFor(authType: .passcode)
            }
        }
    }
    
    @ViewBuilder
    func listItemFor(authType: AuthenticationType) -> some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: authType.title,
                           imageType: .uiImage(authType.icon),
                           rightViewStyle: authType == selectedAuthType ? .checkmark : nil)
            .udListItemInCollectionButtonPadding()
        }, callback: {
            logButtonPressedAnalyticEvents(button: authType.analyticsName)
            Task { @MainActor in
                changeAuthType(authType)
            }
        })
        .padding(EdgeInsets(4))
    }
    
    @ViewBuilder
    func actionsSection() -> some View {
        if selectedAuthType == .passcode {
            UDCollectionSectionBackgroundView {
                changePasscodeButton()
            }
        }
    }
    
    @ViewBuilder
    func changePasscodeButton() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            changePasscode()
        } label: {
            HStack {
                Text(String.Constants.settingsSecurityChangePasscode.localized())
                    .textAttributes(color: .foregroundAccent,
                                    fontSize: 16,
                                    fontWeight: .medium)
                Spacer()
            }
                .frame(height: 24)
                .padding(12)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func securitySettingsSection() -> some View {
        HStack {
            Text(String.Constants.settingsSecurityRequireWhenOpeningHeader.localized())
                .textAttributes(color: .foregroundSecondary,
                                fontSize: 14,
                                fontWeight: .medium)
                .padding(.top, 16)
            Spacer()
        }
        
        UDCollectionSectionBackgroundView {
            Toggle(String.Constants.settingsSecurityOpeningTheApp.localized(), isOn: $shouldRequireSAOnAppOpening)
                .toggleStyle(UDToggleStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
        }
    }
}

// MARK: - Private methods
private extension SecuritySettingsView {
    @MainActor
    func changeAuthType(_ type: AuthenticationType) {
        guard type != selectedAuthType else { return }
        
        switch type {
        case .biometric:
            verifyAuthAndSetBiometricEnabled(true)
        case .passcode:
            verifyAuthAndSetBiometricEnabled(false)
        }
    }
    
    @MainActor
    func verifyAuthAndSetBiometricEnabled(_ isEnabled: Bool) {
        guard let view = appContext.coreAppCoordinator.topVC else { return }
        
        appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm, completionCallback: {
            DispatchQueue.main.async {
                self.setBiometricEnabled(isEnabled)
            }
        }(), cancellationCallback: { })
    }
    
    @MainActor
    func setBiometricEnabled(_ isEnabled: Bool) {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

        if isEnabled {
            appContext.authentificationService.authenticateWithBiometricWith(uiHandler: view) { result in
                if result == true {
                    self.logAnalytic(event: .biometricAuthSuccess)
                } else {
                    self.logAnalytic(event: .biometricAuthFailed)
                }
                
                DispatchQueue.main.async {
                    self.setSettingsBiometricEnabled(result == true)
                }
            }
        } else {
            /// Need to give time for blur view disappear. Otherwise it will stuck forever and be visible if user navigate back.
            DispatchQueue.main.asyncAfter(deadline: .now() + appContext.authentificationService.biometricUIProcessingTime) {
                self.setupPasscode {
                    self.setSettingsBiometricEnabled(false)
                }
            }
        }
    }
    
    func setupPasscode(completion: EmptyCallback? = nil) {
        tabRouter.walletViewNavPath.append(HomeWalletNavigationDestination.setupPasscode(.create(completionCallback: { completion?() }, cancellationCallback: { })))
    }
    
    func setSettingsBiometricEnabled(_ isEnabled: Bool) {
        var settings = User.instance.getSettings()
        settings.touchIdActivated = isEnabled
        User.instance.update(settings: settings)
        id = UUID()
    }
    
    @MainActor
    func changePasscode() {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

        appContext.authentificationService.verifyWith(uiHandler: view, purpose: .enterOld, completionCallback: {
            self.setupPasscode()
        }(), cancellationCallback: nil)
    }
    
    func setRequireSAOnAppOpening(isOn: Bool) {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

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
                shouldRequireSAOnAppOpening = true
            }
        }
    }
}

// MARK: - Private methods
private extension SecuritySettingsView {
    var selectedAuthType: AuthenticationType {
        User.instance.getSettings().touchIdActivated ? .biometric : .passcode
    }
    
    enum AuthenticationType: Hashable, CaseIterable {
        case biometric, passcode
        
        var title: String {
            switch self {
            case .biometric:
                return appContext.authentificationService.biometricsName ?? ""
            case .passcode:
                return String.Constants.settingsSecurityPasscode.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .biometric:
                return appContext.authentificationService.biometricIcon ?? .init()
            case .passcode:
                return .passcodeIcon
            }
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .biometric:
                return .securitySettingsBiometric
            case .passcode:
                return .securitySettingsPasscode
            }
        }
    }
}

#Preview {
    NavigationStack {
        SecuritySettingsView()
    }
}
