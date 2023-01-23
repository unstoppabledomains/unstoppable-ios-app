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
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    
    init(view: SettingsViewProtocol,
         notificationsService: NotificationsServiceProtocol,
         dataAggregatorService: DataAggregatorServiceProtocol) {
        self.view = view
        self.notificationsService = notificationsService
        self.dataAggregatorService = dataAggregatorService
        dataAggregatorService.addListener(self)
    }
    
}

// MARK: - SettingsPresenterProtocol
extension SettingsPresenter: SettingsPresenterProtocol {
    func viewWillAppear() {
        showSettings()
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
                    showSettings()
                case .domainsPFPUpdated:
                    return
                }
            case .failure:
                return
            }
        }
    }
}

// MARK: - Private methods
private extension SettingsPresenter {
    func showSettings() {
        Task {
            let wallets = await dataAggregatorService.getWalletsWithInfo()
            var snapshot = NSDiffableDataSourceSnapshot<SettingsViewController.Section, SettingsViewController.SettingsMenuItem>()
            
            snapshot.appendSections([.main(0)]) // empty header
            
            snapshot.appendSections([.main(1)])
            let interactableDomains = await dataAggregatorService.getDomains().interactableItems()
            if interactableDomains.count > 1 {
                snapshot.appendItems([.homeScreen(UserDefaults.primaryDomainName ?? "")])
            }
            let securityName = User.instance.getSettings().touchIdActivated ? (appContext.authentificationService.biometricsName ?? "") : String.Constants.settingsSecurityPasscode.localized()
            snapshot.appendItems([.wallets("\(wallets.count)"),
                                  .security(securityName),
                                  .appearance(UserDefaults.appearanceStyle)])
            #if TESTFLIGHT
            snapshot.appendItems([.testnet(isOn: User.instance.getSettings().isTestnetUsed)])
            #endif

            
            snapshot.appendSections([.main(2)])
            snapshot.appendItems(SettingsViewController.SettingsMenuItem.supplementaryItems)
            
            snapshot.appendSections([.main(3)])
            
            await view?.applySnapshot(snapshot, animated: false)            
        }
    }
    
    @MainActor
    func showWalletsList() {
        guard let nav = view?.cNavigationController else { return }
        
        UDRouter().showWalletsList(in: nav, shouldShowImportWalletPullUp: false)
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
            self?.showSettings()
        }
    }
    
    func showHomeScreenDomainSelection() {
        guard let view = self.view else { return }

        Task {
            let interactableDomains = await dataAggregatorService.getDomains().interactableItems()
            let result = await UDRouter().showNewPrimaryDomainSelectionScreen(domains: interactableDomains,
                                                                              isFirstPrimaryDomain: false,
                                                                              configuration: .init(selectedDomain: interactableDomains.first(where: { $0.isPrimary }),
                                                                                                   canReverseResolutionETHDomain: false,
                                                                                                   analyticsView: .changePrimaryDomainFromSettings),
                                                                              in: view)
            switch result {
            case .cancelled:
                return
            case .homeDomainSet(let newPrimaryDomain), .homeAndReverseResolutionSet(let newPrimaryDomain):
                await dataAggregatorService.setPrimaryDomainWith(name: newPrimaryDomain.name)
                await view.cNavigationController?.popToRootViewController(animated: true)
            }
        }
    }
}


