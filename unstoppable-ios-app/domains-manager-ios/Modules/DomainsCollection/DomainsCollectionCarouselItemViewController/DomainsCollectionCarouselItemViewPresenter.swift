//
//  DomainsCollectionCarouselItemViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.12.2022.
//

import UIKit

@MainActor
protocol DomainsCollectionCarouselItemViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    func didSelectItem(_ item: DomainsCollectionCarouselItemViewController.Item)
    func setCarouselCardState(_ state: CarouselCardState)
}

final class DomainsCollectionCarouselItemViewPresenter {
    
    typealias CardAction = DomainsCollectionCarouselItemViewController.DomainCardConfiguration.Action
    
    private weak var view: DomainsCollectionCarouselItemViewProtocol?
    
    private var domain: DomainDisplayInfo
    private var walletWithInfo: WalletWithInfo?
    private var cardState: CarouselCardState = .expanded
    static let dashesSeparatorSectionHeight: CGFloat = 16
    private var connectedApps = [any UnifiedConnectAppInfoProtocol]()
    private var cardId = UUID()
    private weak var actionsDelegate: DomainsCollectionCarouselViewControllerActionsDelegate?
    var analyticsName: Analytics.ViewName { .unspecified }

    init(view: DomainsCollectionCarouselItemViewProtocol,
         domain: DomainDisplayInfo,
         cardState: CarouselCardState,
         actionsDelegate: DomainsCollectionCarouselViewControllerActionsDelegate) {
        self.view = view
        self.domain = domain
        self.cardState = cardState
        self.actionsDelegate = actionsDelegate
    }
    
}
 
// MARK: - DomainsCollectionCarouselItemViewPresenterProtocol
extension DomainsCollectionCarouselItemViewPresenter: DomainsCollectionCarouselItemViewPresenterProtocol {
    @MainActor
    func viewDidLoad() {
        appContext.walletConnectService.addListener(self)
        appContext.walletConnectServiceV2.addListener(self)
        appContext.dataAggregatorService.addListener(self)
        appContext.appLaunchService.addListener(self)
        appContext.externalEventsService.addListener(self)
        showDomainData(animated: false, actions: [])
        Task.detached(priority: .low) { [weak self] in
            await self?.showDomainDataWithActions(animated: false)
        }
    }
    
    func didSelectItem(_ item: DomainsCollectionCarouselItemViewController.Item) {
        switch item {
        case .domainCard(let configuration):
            actionsDelegate?.didOccursUIAction(.domainSelected(configuration.domain))
        case .noRecentActivities, .recentActivity:
            return
        }
    }
    
    func setCarouselCardState(_ state: CarouselCardState) {
        guard self.cardState != state else { return }
        
        self.cardState = state
        if !connectedApps.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                Task {
                    await self.showDomainDataWithActions(animated: true)
                }
            }
        }
    }
}

// MARK: - DataAggregatorServiceListener
extension DomainsCollectionCarouselItemViewPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task {
            switch result {
            case .success(let resultType):
                switch resultType {
                case .domainsUpdated(let domains), .domainsPFPUpdated(let domains):
                    if let currentDomain = domains.first(where: { $0.isSameEntity(self.domain )}),
                       currentDomain != self.domain {
                        self.domain = currentDomain
                        await showDomainDataWithActions(animated: false)
                    }
                case .primaryDomainChanged, .walletsListUpdated: return
                }
            case .failure:
                return
            }
        }
    }
}

// MARK: - ExternalEventsServiceListener
extension DomainsCollectionCarouselItemViewPresenter: ExternalEventsServiceListener {
    func didReceive(event: ExternalEvent) {
        Task {
            switch event {
            case .mintingFinished, .domainTransferred, .recordsUpdated, .reverseResolutionSet, .reverseResolutionRemoved, .domainProfileUpdated:
                await showDomainDataWithActions(animated: false)
            case .wcDeepLink, .walletConnectRequest:
                return
            }
        }
    }
}

// MARK: - AppLaunchServiceListener
extension DomainsCollectionCarouselItemViewPresenter: AppLaunchServiceListener {
    func appLaunchServiceDidUpdateAppVersion() {
        Task {
            await showDomainDataWithActions(animated: false)
        }
    }
}

// MARK: - WalletConnectServiceListener
extension DomainsCollectionCarouselItemViewPresenter: WalletConnectServiceListener {
    func didConnect(to app: PushSubscriberInfo?) {
        guard app?.domainName == self.domain.name else { return }
        
        Task {
            await showDomainDataWithActions(animated: true)
        }
    }
    
    func didDisconnect(from app: PushSubscriberInfo?) {
        guard app?.domainName == self.domain.name else { return }

        Task {
            await showDomainDataWithActions(animated: true)
        }
    }
    
    func didCompleteConnectionAttempt() { }
}

// MARK: - Private methods
private extension DomainsCollectionCarouselItemViewPresenter {
    func showDomainDataWithActions(animated: Bool) async {
        let actions = await actionsForDomain()
        let connectedApps = await appContext.walletConnectServiceV2.getConnectedApps().filter({ $0.domain.isSameEntity(domain) })
        self.connectedApps = connectedApps
        await showDomainData(animated: animated, actions: actions)
    }
    
    @MainActor
    func showDomainData(animated: Bool, actions: [CardAction]) {
        let domain = self.domain
        var snapshot = DomainsCollectionCarouselItemSnapshot()
        
        snapshot.appendSections([.domainsCarousel])
        snapshot.appendItems([.domainCard(configuration: .init(id: cardId,
                                                               domain: domain,
                                                               availableActions: actions,
                                                               actionButtonPressedCallback: { [weak self] in
            self?.logButtonPressedAnalyticEvents(button: .domainCardDot,
                                                 parameters: [.domainName : domain.name])
        }))])
         
        if connectedApps.isEmpty {
            snapshot.appendSections([.noRecentActivities])
            snapshot.appendItems([.noRecentActivities(configuration: .init(learnMoreButtonPressedCallback: { [weak self] in
                self?.recentActivitiesLearnMoreButtonPressed()
            }))])
        } else {
            // Spacer
            if cardState == .expanded {
                snapshot.appendSections([.emptySeparator(height: 40)])
            }
            
            // Separator
            if !UserDefaults.didShowSwipeDomainCardTutorial,
               cardState == .expanded {
                snapshot.appendSections([.tutorialDashesSeparator(height: Self.dashesSeparatorSectionHeight)])
            } else {
                snapshot.appendSections([.dashesSeparator(height: Self.dashesSeparatorSectionHeight)])
            }
            
            // Recent activities
            snapshot.appendSections([.recentActivity(numberOfActivities: connectedApps.count)])
            for app in connectedApps {
                let actions: [DomainsCollectionCarouselItemViewController.RecentActivitiesConfiguration.Action] = [.openApp(callback: { [weak self] in
                    self?.handleOpenAppAction(app)
                }),
                                                                                                                   .disconnect(callback: { [weak self] in
                    self?.handleDisconnectAppAction(app)
                })]
                snapshot.appendItems([.recentActivity(configuration: .init(connectedApp: app,
                                                                           availableActions: actions,
                                                                           actionButtonPressedCallback: { [weak self] in
                    self?.logButtonPressedAnalyticEvents(button: .connectedAppDot,
                                                         parameters: [.wcAppName : app.displayName,
                                                                      .domainName: domain.name])
                }))])
            }
        }
        
        view?.applySnapshot(snapshot, animated: animated)
    }
    
    func actionsForDomain() async -> [CardAction] {
        let domain = self.domain
        var vaultName: String?
        if let walletWithInfo = self.walletWithInfo,
           walletWithInfo.displayInfo?.address == domain.ownerWallet {
            vaultName = walletWithInfo.displayInfo?.walletSourceName
        } else {
            let walletWithInfo = await appContext.dataAggregatorService.getWalletsWithInfo().first(where: { $0.wallet.owns(domain: domain) })
            self.walletWithInfo = walletWithInfo
            vaultName = walletWithInfo?.displayInfo?.walletSourceName
        }
        
        var actions: [CardAction] = [.copyDomain(callback: { [weak self] in
            self?.logButtonPressedAnalyticEvents(button: .copyDomain, parameters: [.domainName: domain.name])
            self?.copyDomainName(domain.name)
        }),
                                     .viewVault(vaultName: vaultName ?? "",
                                                vaultAddress: domain.ownerWallet ?? "",
                                                callback: { [weak self] in
            self?.logButtonPressedAnalyticEvents(button: .showWalletDetails, parameters: [.domainName: domain.name])
            self?.didTapShowWalletDetailsButton()
        })]
        
        if !domain.isSetForRR,
           domain.isInteractable,
           let wallet = walletWithInfo?.wallet {
            let isEnabled = await appContext.dataAggregatorService.isReverseResolutionChangeAllowed(for: wallet)
            
            actions.append(.setUpRR(isEnabled: isEnabled,
                                    callback: { [weak self] in
                self?.logButtonPressedAnalyticEvents(button: .setReverseResolution, parameters: [.domainName: domain.name])
                self?.showSetupReverseResolutionModule()
            }))
        }
        
        actions.append(.rearrange(callback: { [weak self] in
            self?.rearrangeDomains()
        }))
        
        return actions
    }
    
    func handleOpenAppAction(_ app: any UnifiedConnectAppInfoProtocol) {
        logButtonPressedAnalyticEvents(button: .open,
                                       parameters: [.wcAppName: app.appName,
                                                    .domainName: domain.name])
        guard let appUrl = URL(string: app.appUrlString) else { return }
        
        UIApplication.shared.open(appUrl)
    }
    
    func handleDisconnectAppAction(_ app: any UnifiedConnectAppInfoProtocol) {
        logButtonPressedAnalyticEvents(button: .disconnectApp,
                                       parameters: [.wcAppName: app.appName,
                                                    .domainName: domain.name])
        Task {
            switch app.appInfo.dAppInfoInternal {
            case .version1(let session): appContext.walletConnectService.disconnect(peerId: session.dAppInfo.peerId)
            case .version2(_): try await appContext.walletConnectServiceV2.disconnect(app: app)
            }
        }
    }
    
    func recentActivitiesLearnMoreButtonPressed() {
        actionsDelegate?.didOccursUIAction(.recentActivityLearnMore)
    }
}

// MARK: - Private methods
private extension DomainsCollectionCarouselItemViewPresenter {
    func copyDomainName(_ domainName: DomainName) {
        UIPasteboard.general.string = domainName
        DispatchQueue.main.async { [weak self] in
            self?.actionsDelegate?.didOccursUIAction(.domainNameCopied)
        }
    }
    
    func showSetupReverseResolutionModule() {
        Task { @MainActor in
            guard let navigation = view?.containerViewController?.cNavigationController,
                  let walletWithInfo,
                  let walletInfo = walletWithInfo.displayInfo else { return }
            
            UDRouter().showSetupChangeReverseResolutionModule(in: navigation,
                                                              wallet: walletWithInfo.wallet,
                                                              walletInfo: walletInfo,
                                                              domain: domain,
                                                              resultCallback: { [weak self] in
                self?.didSetDomainForReverseResolution()
            })
        }
    }
    
    func didSetDomainForReverseResolution() {
        Task {
            await showDomainDataWithActions(animated: true)
        }
    }
    
    func didTapShowWalletDetailsButton() {
        Task { @MainActor in
            guard let navigation = view?.containerViewController?.cNavigationController,
                  let walletWithInfo,
                  let walletInfo = walletWithInfo.displayInfo else { return }
            
            UDRouter().showWalletDetailsOf(wallet: walletWithInfo.wallet,
                                           walletInfo: walletInfo,
                                           source: .domainsCollection,
                                           in: navigation)
        }
    }
    
    func rearrangeDomains() {
        DispatchQueue.main.async { [weak self] in
            self?.actionsDelegate?.didOccursUIAction(.rearrangeDomains)
        }
    }
}
