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
    func didPullToRefresh()
}

enum DomainsCollectionCarouselItemDisplayMode {
    case domain(DomainDisplayInfo)
    case empty
}

final class DomainsCollectionCarouselItemViewPresenter {
    
    typealias CardAction = DomainsCollectionCarouselItemViewController.DomainCardConfiguration.Action
    
    private weak var view: DomainsCollectionCarouselItemViewProtocol?
    
    private var mode: DomainsCollectionCarouselItemDisplayMode
    private var walletWithInfo: WalletWithInfo?
    private var cardState: CarouselCardState = .expanded
    static let dashesSeparatorSectionHeight: CGFloat = 16
    private var connectedApps = [any UnifiedConnectAppInfoProtocol]()
    private var nfts: [NFTModel]?
    private var cardId = UUID()
    private weak var actionsDelegate: DomainsCollectionCarouselViewControllerActionsDelegate?
    private var didShowSwipeDomainCardTutorial = UserDefaults.didShowSwipeDomainCardTutorial
    private var visibleDataType: DomainsCollectionVisibleDataType = DomainsCollectionVisibleDataType.allCases.first!
    var analyticsName: Analytics.ViewName { .unspecified }

    init(view: DomainsCollectionCarouselItemViewProtocol,
         mode: DomainsCollectionCarouselItemDisplayMode,
         cardState: CarouselCardState,
         actionsDelegate: DomainsCollectionCarouselViewControllerActionsDelegate) {
        self.view = view
        self.mode = mode
        self.cardState = cardState
        self.actionsDelegate = actionsDelegate
    }
    
}
 
// MARK: - DomainsCollectionCarouselItemViewPresenterProtocol
extension DomainsCollectionCarouselItemViewPresenter: DomainsCollectionCarouselItemViewPresenterProtocol {
    @MainActor
    func viewDidLoad() {
        appContext.wcRequestsHandlingService.addListener(self)
        appContext.dataAggregatorService.addListener(self)
        appContext.appLaunchService.addListener(self)
        appContext.externalEventsService.addListener(self)
        appContext.walletNFTsService.addListener(self)
        showDomainData(animated: false, actions: [])
        Task.detached(priority: .low) { [weak self] in
            await self?.showDomainDataWithActions(animated: false)
        }
    }
    
    func didSelectItem(_ item: DomainsCollectionCarouselItemViewController.Item) {
        switch item {
        case .domainCard(let configuration):
            actionsDelegate?.didOccurUIAction(.domainSelected(configuration.domain))
        case .nft(let configuration):
            actionsDelegate?.didOccurUIAction(.nftSelected(configuration.nft))
        case .noRecentActivities, .recentActivity, .dataTypeSelector:
            return
        case .getDomainCard:
            UDVibration.buttonTap.vibrate()
            actionsDelegate?.didOccurUIAction(.purchaseDomains)
        }
    }
    
    func setCarouselCardState(_ state: CarouselCardState) {
        guard self.cardState != state else { return }
        
        func isSwipeTutorialValueChanged() -> Bool {
            UserDefaults.didShowSwipeDomainCardTutorial != didShowSwipeDomainCardTutorial
        }
        
        self.cardState = state
        if !connectedApps.isEmpty || isSwipeTutorialValueChanged() || !didShowSwipeDomainCardTutorial {
            self.didShowSwipeDomainCardTutorial = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                Task {
                    await self.showDomainDataWithActions(animated: true)
                }
            }
        }
    }
    
    @MainActor
    func didPullToRefresh() {
        guard case .domain(let domain) = mode else { return }
        
        Task {
            do {
                try await appContext.walletNFTsService.refreshNFTsFor(domainName: domain.name)
            } catch {
                view?.endRefreshing()
            }
        }
    }
}

// MARK: - DataAggregatorServiceListener
extension DomainsCollectionCarouselItemViewPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task {
            if case .domain(let domain) = mode {
                switch result {
                case .success(let resultType):
                    switch resultType {
                    case .domainsUpdated(let domains), .domainsPFPUpdated(let domains):
                        if let currentDomain = domains.first(where: { $0.isSameEntity(domain )}),
                           currentDomain != domain {
                            self.mode = .domain(currentDomain)
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
}

// MARK: - ExternalEventsServiceListener
extension DomainsCollectionCarouselItemViewPresenter: ExternalEventsServiceListener {
    func didReceive(event: ExternalEvent) {
        Task {
            switch event {
            case .mintingFinished, .domainTransferred, .recordsUpdated, .reverseResolutionSet, .reverseResolutionRemoved, .domainProfileUpdated, .parkingStatusLocal:
                await showDomainDataWithActions(animated: false)
            case .wcDeepLink, .walletConnectRequest, .badgeAdded, .chatMessage, .chatChannelMessage, .chatXMTPMessage, .chatXMTPInvite, .domainFollowerAdded:
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
extension DomainsCollectionCarouselItemViewPresenter: WalletConnectServiceConnectionListener {
    func didConnect(to app: UnifiedConnectAppInfo) {
        guard case .domain(let domain) = mode,
              app.domain.isSameEntity(domain) else { return }
        
        Task {
            await showDomainDataWithActions(animated: true)
        }
    }
    
    func didDisconnect(from app: UnifiedConnectAppInfo) {
        guard case .domain(let domain) = mode,
              app.domain.isSameEntity(domain) else { return }

        Task {
            await showDomainDataWithActions(animated: true)
        }
    }
    
    func didCompleteConnectionAttempt() { }
}

// MARK: - WalletNFTsServiceListener
extension DomainsCollectionCarouselItemViewPresenter: WalletNFTsServiceListener {
    func didRefreshNFTs(_ nfts: [NFTModel], for domainName: DomainName) {
        if case .domain(let domain) = self.mode,
           domain.name == domainName {
            setNFTs(nfts)
            Task {
                await showDomainDataWithActions(animated: true)
                await view?.endRefreshing()
            }
        }
    }
}

// MARK: - Private methods
private extension DomainsCollectionCarouselItemViewPresenter {
    func showDomainDataWithActions(animated: Bool) async {
        let actions = await actionsForDomain()
        if case .domain(let domain) = mode {
            let connectedApps = await appContext.walletConnectServiceV2.getConnectedApps().filter({ $0.domain.isSameEntity(domain) })
            self.connectedApps = connectedApps
            
            if self.nfts == nil {
                let nfts = (try? await appContext.walletNFTsService.getImageNFTsFor(domainName: domain.name)) ?? []
                setNFTs(nfts)
            }
        }
        await showDomainData(animated: animated, actions: actions)
    }
    
    func setNFTs(_ nfts: [NFTModel]) {
        self.nfts = nfts.filter({ $0.public && !$0.isUDDomainNFT })
    }
    
    @MainActor
    func showDomainData(animated: Bool, actions: [CardAction]) {
        switch mode {
        case .domain(let domain):
            showDataForDomain(domain, animated: animated, actions: actions)
        case .empty:
            showDataForDomain(nil, animated: animated, actions: actions)
        }
    }
    
    @MainActor
    func showDataForDomain(_ domain: DomainDisplayInfo?, animated: Bool, actions: [CardAction]) {
        var snapshot = DomainsCollectionCarouselItemSnapshot()
        
        snapshot.appendSections([.domainsCarousel])
        if let domain {
            snapshot.appendItems([.domainCard(configuration: .init(id: cardId,
                                                                   domain: domain,
                                                                   availableActions: actions,
                                                                   actionButtonPressedCallback: { [weak self] in
                self?.logButtonPressedAnalyticEvents(button: .domainCardDot,
                                                     parameters: [.domainName : domain.name])
            }))])
        } else {
            snapshot.appendItems([.getDomainCard])
        }
        
        var isTutorialOn = false
        if !didShowSwipeDomainCardTutorial,
           cardState == .expanded {
            isTutorialOn = true
        }
        
        snapshot.appendSections([.emptySeparator(height: emptySeparatorHeightForExpandedState())])
        if isTutorialOn {
            snapshot.appendSections([.tutorialDashesSeparator(height: Self.dashesSeparatorSectionHeight)])
        } else {
            snapshot.appendSections([.dashesSeparator(height: Self.dashesSeparatorSectionHeight)])
        }
        
        if let domain {
            if domain.isInteractable {
                snapshot.appendSections([.dataTypeSelector])
                snapshot.appendItems([.dataTypeSelector(configuration: .init(selectedDataType: visibleDataType,
                                                                             dataTypeChangedCallback: { [weak self] dataType in
                    self?.visibleDataTypeChanged(dataType)
                }))])
            }
            
            addActivitiesSection(in: &snapshot, domain: domain, isTutorialOn: isTutorialOn)
        } else {
            
        }
        
        view?.applySnapshot(snapshot, animated: animated)
    }
    
    func emptySeparatorHeightForExpandedState() -> CGFloat {
        20
    }
    
    func visibleDataTypeChanged(_ newVisibleDataType: DomainsCollectionVisibleDataType) {
        self.visibleDataType = newVisibleDataType
        logButtonPressedAnalyticEvents(button: .domainHomeDataType,
                                       parameters: [.dataType: newVisibleDataType.analyticIdentifier])
        Task {
            await showDomainDataWithActions(animated: true)
        }
    }
}

// MARK: - NFTs Section
private extension DomainsCollectionCarouselItemViewPresenter {
    func addNFTsSection(in snapshot: inout DomainsCollectionCarouselItemSnapshot) {
        if let nfts,
           !nfts.isEmpty {
            snapshot.appendSections([.nfts])
            snapshot.appendItems(nfts.map({ DomainsCollectionCarouselItemViewController.Item.nft(configuration: .init(nft: $0)) }))
        } else {
            addEmptyState(in: &snapshot)
        }
    }
    
    func addConnectedAppsSection(in snapshot: inout DomainsCollectionCarouselItemSnapshot,
                                 domain: DomainDisplayInfo,
                                 isTutorialOn: Bool) {
        if connectedApps.isEmpty {
            snapshot.appendSections([.noRecentActivities])
            snapshot.appendItems([.noRecentActivities(configuration: .init(learnMoreButtonPressedCallback: { [weak self] in
                self?.recentActivitiesLearnMoreButtonPressed()
            }, isTutorialOn: isTutorialOn, dataType: .activity))])
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
}

// MARK: - Activities Section
private extension DomainsCollectionCarouselItemViewPresenter {
    func addActivitiesSection(in snapshot: inout DomainsCollectionCarouselItemSnapshot, domain: DomainDisplayInfo, isTutorialOn: Bool) {
        if case .parking = domain.state {
            snapshot.appendSections([.noRecentActivities])
            snapshot.appendItems([.noRecentActivities(configuration: .init(learnMoreButtonPressedCallback: { [weak self] in
                self?.recentActivitiesLearnMoreButtonPressed()
            }, isTutorialOn: isTutorialOn, dataType: .parkedDomain))])
        } else {
            if case .NFT = visibleDataType {
                addNFTsSection(in: &snapshot)
            } else {
                addConnectedAppsSection(in: &snapshot,
                                        domain: domain,
                                        isTutorialOn: isTutorialOn)
            }
        }
    }
}

// MARK: - Empty section
private extension DomainsCollectionCarouselItemViewPresenter {
    func addEmptyState(in snapshot: inout DomainsCollectionCarouselItemSnapshot) {
        var isTutorialOn = false
        // Separator
        if !didShowSwipeDomainCardTutorial,
           cardState == .expanded {
            isTutorialOn = true
            snapshot.appendSections([.emptySeparator(height: emptySeparatorHeightForExpandedState())])
            snapshot.appendSections([.tutorialDashesSeparator(height: Self.dashesSeparatorSectionHeight)])
        }
        
        snapshot.appendSections([.noRecentActivities])
        snapshot.appendItems([.noRecentActivities(configuration: .init(learnMoreButtonPressedCallback: { [weak self] in
            self?.recentActivitiesLearnMoreButtonPressed()
        },
                                                                       isTutorialOn: isTutorialOn,
                                                                       dataType: visibleDataType))])
    }
}

// MARK: - Actions
private extension DomainsCollectionCarouselItemViewPresenter {
    func actionsForDomain() async -> [CardAction] {
        guard case .domain(let domain) = mode else { return [] }
        
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
        guard case .domain(let domain) = mode else { return }
        
        logButtonPressedAnalyticEvents(button: .open,
                                       parameters: [.wcAppName: app.appName,
                                                    .domainName: domain.name])
        guard let appUrl = URL(string: app.appUrlString) else { return }
        
        UIApplication.shared.open(appUrl)
    }
    
    func handleDisconnectAppAction(_ app: any UnifiedConnectAppInfoProtocol) {
        guard case .domain(let domain) = mode else { return }

        logButtonPressedAnalyticEvents(button: .disconnectApp,
                                       parameters: [.wcAppName: app.appName,
                                                    .domainName: domain.name])
        Task {
            try await appContext.walletConnectServiceV2.disconnect(app: app)
        }
    }
    
    func recentActivitiesLearnMoreButtonPressed() {
        switch mode {
        case .domain(let domain):
            if case .parking = domain.state {
                actionsDelegate?.didOccurUIAction(.parkedDomainLearnMore)
            } else {
                switch visibleDataType {
                case .NFT:
                    Task {
                        do {
                            let domain = try await appContext.dataAggregatorService.getDomainWith(name: domain.name)
                            try await NetworkService().createNFTGallery(for: domain)
                            await didPullToRefresh()
                        } catch {
                            await view?.showAlertWith(error: error, handler: nil)
                        }
                    }
                case .activity:
                    actionsDelegate?.didOccurUIAction(.recentActivityLearnMore)
                case .parkedDomain:
                    actionsDelegate?.didOccurUIAction(.parkedDomainLearnMore)
                case .getDomain:
                    return 
                }
            }
        case .empty:
            actionsDelegate?.didOccurUIAction(.recentActivityGetDomain)
        }
    }
}

// MARK: - Private methods
private extension DomainsCollectionCarouselItemViewPresenter {
    func copyDomainName(_ domainName: DomainName) {
        UIPasteboard.general.string = domainName
        DispatchQueue.main.async { [weak self] in
            self?.actionsDelegate?.didOccurUIAction(.domainNameCopied)
        }
    }
    
    func showSetupReverseResolutionModule() {
        guard case .domain(let domain) = mode else { return }

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
            self?.actionsDelegate?.didOccurUIAction(.rearrangeDomains)
        }
    }
}
