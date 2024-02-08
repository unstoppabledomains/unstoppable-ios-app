//
//  SettingsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit
import Combine

@MainActor
protocol SettingsPresenterProtocol: BasePresenterProtocol {
    func didSelectMenuItem(_ menuItem: SettingsViewController.SettingsMenuItem)
}

@MainActor
final class SettingsPresenter: ViewAnalyticsLogger {
    
    private weak var view: SettingsViewProtocol?
    
    private let notificationsService: NotificationsServiceProtocol
    private let firebaseAuthenticationService: any FirebaseAuthenticationServiceProtocol
    private var loginCallback: LoginFlowNavigationController.LoggedInCallback?
    private var cancellables: Set<AnyCancellable> = []

    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    
    init(view: SettingsViewProtocol,
         loginCallback: LoginFlowNavigationController.LoggedInCallback?,
         notificationsService: NotificationsServiceProtocol,
         firebaseAuthenticationService: any FirebaseAuthenticationServiceProtocol) {
        self.view = view
        self.loginCallback = loginCallback
        self.notificationsService = notificationsService
        self.firebaseAuthenticationService = firebaseAuthenticationService
        appContext.walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.showSettings()
        }.store(in: &cancellables)
        firebaseAuthenticationService.authorizedUserPublisher.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.showSettings()
        }.store(in: &cancellables)
    }
    
}

// MARK: - SettingsPresenterProtocol
extension SettingsPresenter: SettingsPresenterProtocol {
    func viewDidLoad() {
        showSettings()
    }
    
    func viewWillAppear() {
        showSettings()
    }
    
    func didSelectMenuItem(_ menuItem: SettingsViewController.SettingsMenuItem) {
        logButtonPressedAnalyticEvents(button: menuItem.analyticsName)
        UDVibration.buttonTap.vibrate()
        switch menuItem {
        case .wallets:
            showWalletsList()
        case .security:
            showSecuritySettings()
        case .appearance(let selectedAppearance):
            showSelectAppearanceStyle(selectedStyle: selectedAppearance)
        case .testnet(let isOn):
            setTestnet(on: isOn)
        case .rateUs:
            AppReviewService.shared.requestToWriteReviewInAppStore()
        case .learn:
            view?.openLink(.learn)
        case .twitter:
            view?.openUDTwitter()
        case .support:
            view?.openFeedbackMailForm()
        case .legal:
            showLegalOptions()
        case .websiteAccount:
            showLoginScreen()
        case .inviteFriends:
            showInviteFriendsScreen()
        }
    }
}

// MARK: - Private methods
private extension SettingsPresenter {
    func showSettings() {
        let wallets = appContext.walletsDataService.wallets
        var snapshot = NSDiffableDataSourceSnapshot<SettingsViewController.Section, SettingsViewController.SettingsMenuItem>()
        
        snapshot.appendSections([.main(0)]) // empty header
        
        snapshot.appendSections([.main(1)])
        let interactableDomains = wallets.combinedDomains().interactableItems()

        let securityName = User.instance.getSettings().touchIdActivated ? (appContext.authentificationService.biometricsName ?? "") : String.Constants.settingsSecurityPasscode.localized()
        snapshot.appendItems([.wallets("\(wallets.count)"),
                              .security(securityName)])
#if TESTFLIGHT
        snapshot.appendItems([.testnet(isOn: User.instance.getSettings().isTestnetUsed)])
#endif
        let firebaseUser = firebaseAuthenticationService.firebaseUser
        snapshot.appendItems([.websiteAccount(user: firebaseUser)])
        
        
        snapshot.appendSections([.main(2)])
        if !interactableDomains.isEmpty {
            snapshot.appendItems([.inviteFriends])
        }
        snapshot.appendItems(SettingsViewController.SettingsMenuItem.supplementaryItems)
        
        snapshot.appendSections([.main(3)])
        
        view?.applySnapshot(snapshot, animated: false)
    }
    
    func showWalletsList() {
        view?.openWalletsList(initialAction: .none)
    }
    
    func showLegalOptions() {
        guard let view = self.view else { return }
        
        Task {
            do {
                let legalType = try await appContext.pullUpViewService.showLegalSelectionPullUp(in: view)
                await view.dismissPullUpMenu()
                switch legalType {
                case .termsOfUse:
                    view.openLink(.termsOfUse)
                case .privacyPolicy:
                    view.openLink(.privacyPolicy)
                }
            } catch { }
        }
    }
    
    func setTestnet(on isOn: Bool) {
        var settings = User.instance.getSettings()
        switch isOn {
        case false: settings.networkType = .mainnet
        case true: settings.networkType = .testnet
        }
        User.instance.update(settings: settings)
        Storage.instance.cleanAllCache()
        firebaseAuthenticationService.logOut()
        appContext.messagingService.logout()
        updateAppVersion()
        appContext.walletsDataService.didChangeEnvironment()
        notificationsService.updateTokenSubscriptions()
    }
    
    private func updateAppVersion() {
        Task { await appContext.userDataService.getLatestAppVersion() }
    }
    
    func showSecuritySettings() {
        guard let nav = view?.cNavigationController else { return }
        
        UDRouter().showSecuritySettingsScreen(in: nav)
    }
    
    func showSelectAppearanceStyle(selectedStyle: UIUserInterfaceStyle) {
        guard let view = self.view else { return }
        
        appContext.pullUpViewService.showAppearanceStyleSelectionPullUp(in: view, selectedStyle: selectedStyle) { [weak self] newStyle in
            self?.logAnalytic(event: .didChangeTheme, parameters: [.theme: newStyle.analyticsName])
            SceneDelegate.shared?.setAppearanceStyle(newStyle)
            self?.showSettings()
        }
    }
    
    func showLoginScreen() {
        guard let view else { return }
        
        if let firebaseUser = firebaseAuthenticationService.firebaseUser {
            Task {
                do {
                    let domainsCount = appContext.firebaseParkedDomainsService.getCachedDomains().count
                    let profileAction = try await appContext.pullUpViewService.showUserProfilePullUp(with: firebaseUser.email ?? "Twitter account",
                                                                                                     domainsCount: domainsCount,
                                                                                                     in: view)
                    switch profileAction {
                    case .logOut:
                        try await appContext.pullUpViewService.showLogoutConfirmationPullUp(in: view)
                        await view.dismissPullUpMenu()
                        try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                        firebaseAuthenticationService.logOut()
                        appContext.toastMessageService.showToast(.userLoggedOut, isSticky: false)
                    }
                } catch { }
            }
        } else {
            UDRouter().runLoginFlow(with: .default,
                                    loggedInCallback: { [weak self] result in
                self?.loginCallback?(result)
            },
                                    in: view)
        }
    }
    
    func showInviteFriendsScreen() {
        guard let nav = view?.cNavigationController else { return }

        let interactableDomains = appContext.walletsDataService.wallets.combinedDomains().interactableItems()
        
        guard let domainDisplayInfo = interactableDomains.first else {
            Debugger.printFailure("Failed to get domain for referral code", critical: true)
            return }
        
        let domain = domainDisplayInfo.toDomainItem()
        
        UDRouter().showInviteFriendsScreen(domain: domain,
                                           in: nav)
    }
}


