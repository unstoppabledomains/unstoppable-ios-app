//
//  SettingsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit

protocol SettingsPresenterProtocol: BasePresenterProtocol {
    func didSelectMenuItem(_ menuItem: SettingsViewController.SettingsMenuItem)
}

final class SettingsPresenter: ViewAnalyticsLogger {
    
    private weak var view: SettingsViewProtocol?
    
    private let notificationsService: NotificationsServiceProtocol
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private let firebaseInteractionService: FirebaseInteractionServiceProtocol
    private var firebaseUser: FirebaseUser?
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    
    init(view: SettingsViewProtocol,
         notificationsService: NotificationsServiceProtocol,
         dataAggregatorService: DataAggregatorServiceProtocol,
         firebaseInteractionService: FirebaseInteractionServiceProtocol) {
        self.view = view
        self.notificationsService = notificationsService
        self.dataAggregatorService = dataAggregatorService
        self.firebaseInteractionService = firebaseInteractionService
        dataAggregatorService.addListener(self)
        firebaseInteractionService.addListener(self)
    }
    
}

// MARK: - SettingsPresenterProtocol
extension SettingsPresenter: SettingsPresenterProtocol {
    func viewDidLoad() {
        Task {
            firebaseUser = try? await firebaseInteractionService.getUserProfile()
            showSettingsAsync()
        }        
    }
    
    func viewWillAppear() {
        showSettingsAsync()
    }
    
    func didSelectMenuItem(_ menuItem: SettingsViewController.SettingsMenuItem) {
        Task {
            logButtonPressedAnalyticEvents(button: menuItem.analyticsName)
            await MainActor.run {
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
                case .homeScreen:
                    showHomeScreenDomainSelection()
                case .websiteAccount:
                    showLoginScreen()
                }
            }
        }
    }
}

// MARK: - DataAggregatorServiceListener
extension SettingsPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task {
            switch result {
            case .success(let result):
                switch result {
                case .walletsListUpdated, .domainsUpdated, .primaryDomainChanged:
                    showSettingsAsync()
                case .domainsPFPUpdated:
                    return
                }
            case .failure:
                return
            }
        }
    }
}

// MARK: - FirebaseInteractionServiceListener
extension SettingsPresenter: FirebaseInteractionServiceListener {
    func firebaseUserUpdated(firebaseUser: FirebaseUser?) {
        self.firebaseUser = firebaseUser
        showSettingsAsync()
    }
}

// MARK: - Private methods
private extension SettingsPresenter {
    func showSettingsAsync() {
        Task {
            let wallets = await dataAggregatorService.getWalletsWithInfo()
            var snapshot = NSDiffableDataSourceSnapshot<SettingsViewController.Section, SettingsViewController.SettingsMenuItem>()
            
            snapshot.appendSections([.main(0)]) // empty header
            
            snapshot.appendSections([.main(1)])
            let interactableDomains = await dataAggregatorService.getDomainsDisplayInfo().interactableItems()
            if let primaryDomain = interactableDomains.first {
                snapshot.appendItems([.homeScreen(primaryDomain.name)])
            }
            let securityName = User.instance.getSettings().touchIdActivated ? (appContext.authentificationService.biometricsName ?? "") : String.Constants.settingsSecurityPasscode.localized()
            snapshot.appendItems([.wallets("\(wallets.count)"),
                                  .security(securityName),
                                  .appearance(UserDefaults.appearanceStyle)])
            #if TESTFLIGHT
            snapshot.appendItems([.testnet(isOn: User.instance.getSettings().isTestnetUsed)])
            #endif
            snapshot.appendItems([.websiteAccount(userEmail: firebaseUser?.email)])

            
            snapshot.appendSections([.main(2)])
            snapshot.appendItems(SettingsViewController.SettingsMenuItem.supplementaryItems)
            
            snapshot.appendSections([.main(3)])
            
            await view?.applySnapshot(snapshot, animated: false)            
        }
    }
    
    @MainActor
    func showWalletsList() {
        guard let nav = view?.cNavigationController else { return }
        
        UDRouter().showWalletsList(in: nav, initialAction: .none)
    }
    
    @MainActor
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
        StripeService.shared.setup()
        firebaseInteractionService.logout()
        updateAppVersion()
        Task { await dataAggregatorService.aggregateData() }
        notificationsService.updateTokenSubscriptions()
    }
    
    private func updateAppVersion() {
        Task { await appContext.userDataService.getLatestAppVersion() }
    }
    
    @MainActor
    func showSecuritySettings() {
        guard let nav = view?.cNavigationController else { return }
        
        UDRouter().showSecuritySettingsScreen(in: nav)
    }
    
    @MainActor
    func showSelectAppearanceStyle(selectedStyle: UIUserInterfaceStyle) {
        guard let view = self.view else { return }
        
        appContext.pullUpViewService.showAppearanceStyleSelectionPullUp(in: view, selectedStyle: selectedStyle) { [weak self] newStyle in
            self?.logAnalytic(event: .didChangeTheme, parameters: [.theme: newStyle.analyticsName])
            SceneDelegate.shared?.setAppearanceStyle(newStyle)
            self?.showSettingsAsync()
        }
    }
    
    func showHomeScreenDomainSelection() {
        guard let view = self.view else { return }

        Task {
            let interactableDomains = await dataAggregatorService.getDomainsDisplayInfo().interactableItems()
            let result = await UDRouter().showNewPrimaryDomainSelectionScreen(domains: interactableDomains,
                                                                              isFirstPrimaryDomain: false,
                                                                              configuration: .init(canReverseResolutionETHDomain: false,
                                                                                                   analyticsView: .sortDomainsFromSettings),
                                                                              in: view)
            switch result {
            case .cancelled:
                return
            case .domainsOrderSet(let domains), .domainsOrderAndReverseResolutionSet(let domains, _):
                await dataAggregatorService.setDomainsOrder(using: domains)
                await view.cNavigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    @MainActor
    func showLoginScreen() {
        guard let view,
              let nav = view.cNavigationController else { return }
        
        if appContext.firebaseAuthService.isAuthorised {
            Task {
//                do {
//                    try await appContext.pullUpViewService.showLogoutConfirmationPullUp(in: view)
//                    await view.dismissPullUpMenu()
//                    try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
//                    firebaseInteractionService.logout()
//                } catch { }
                                
                do {
                    let domains = try await appContext.firebaseInteractionService.getParkedDomains()
                    let displayInfo = domains.map({ FirebaseDomainDisplayInfo(firebaseDomain: $0) })
                    UDRouter().showParkedDomainsFoundModuleWith(domains: displayInfo,
                                                                in: nav)
                } catch {
//                    authFailedWith(error: error)
                }
            }
        } else {
            UDRouter().showLoginScreen(in: nav)
        }
    }
}


