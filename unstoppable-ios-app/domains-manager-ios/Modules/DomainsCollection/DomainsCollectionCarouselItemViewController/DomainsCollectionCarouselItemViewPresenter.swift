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

final class DomainsCollectionCarouselItemViewPresenter {
    
    typealias CardAction = DomainsCollectionCarouselItemViewController.DomainCardConfiguration.Action
    
    private weak var view: DomainsCollectionCarouselItemViewProtocol?
    
    private var domain: DomainDisplayInfo
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
            actionsDelegate?.didOccursUIAction(.domainSelected(configuration.domain))
        case .nft(let configuration):
            actionsDelegate?.didOccursUIAction(.nftSelected(configuration.nft))
        case .noRecentActivities, .recentActivity, .dataTypeSelector:
            return
        }
    }
    
    func setCarouselCardState(_ state: CarouselCardState) {
        guard self.cardState != state else { return }
        
        func isSwipeTutorialValueChanged() -> Bool {
            UserDefaults.didShowSwipeDomainCardTutorial != didShowSwipeDomainCardTutorial
        }
        
        self.cardState = state
        if !connectedApps.isEmpty || isSwipeTutorialValueChanged() {
            self.didShowSwipeDomainCardTutorial = UserDefaults.didShowSwipeDomainCardTutorial
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                Task {
                    await self.showDomainDataWithActions(animated: true)
                }
            }
        }
    }
    
    @MainActor
    func didPullToRefresh() {
        guard let walletWithInfo else { return }
        
        Task {
            do {
                try await appContext.walletNFTsService.refreshNFTsFor(walletAddress: walletWithInfo.wallet.address)
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
extension DomainsCollectionCarouselItemViewPresenter: WalletConnectServiceConnectionListener {
    func didConnect(to app: UnifiedConnectAppInfo) {
        guard app.domain.isSameEntity(self.domain) else { return }
        
        Task {
            await showDomainDataWithActions(animated: true)
        }
    }
    
    func didDisconnect(from app: UnifiedConnectAppInfo) {
        guard app.domain.isSameEntity(self.domain) else { return }

        Task {
            await showDomainDataWithActions(animated: true)
        }
    }
    
    func didCompleteConnectionAttempt() { }
}

// MARK: - WalletNFTsServiceListener
extension DomainsCollectionCarouselItemViewPresenter: WalletNFTsServiceListener {
    func didRefreshNFTs(_ nfts: [NFTModel], for walletAddress: HexAddress) {
        if walletWithInfo?.wallet.address == walletAddress {
            self.nfts = nfts
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
        let connectedApps = await appContext.walletConnectServiceV2.getConnectedApps().filter({ $0.domain.isSameEntity(domain) })
        self.connectedApps = connectedApps
        if self.nfts == nil,
           let walletWithInfo {
            let nfts = (try? await appContext.walletNFTsService.getImageNFTsFor(wallet: walletWithInfo.wallet)) ?? []
            self.nfts = nfts.filter({ !$0.isDomainNFT })
        }
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
        
        snapshot.appendSections([.dataTypeSelector])
        snapshot.appendItems([.dataTypeSelector(configuration: .init(selectedDataType: visibleDataType,
                                                                     dataTypeChangedCallback: { [weak self] dataType in
            self?.visibleDataTypeChanged(dataType)
        }))])
         
        switch visibleDataType {
        case .NFT:
            addNFTsSection(in: &snapshot)
        case .activity:
            addActivitiesSection(in: &snapshot, domain: domain)
        }
        
        view?.applySnapshot(snapshot, animated: animated)
    }
    
    func emptySeparatorHeightForExpandedState() -> CGFloat {
        switch deviceSize {
        case .i4Inch:
            return 14
        case .i5_4Inch:
            return 26
        case .i5_5Inch:
            return 50
        case .i5_8Inch:
            return 30
        default:
            return 40
        }
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
        snapshot.appendSections([.nfts])
        if let nfts {
            snapshot.appendItems(nfts.map({ DomainsCollectionCarouselItemViewController.Item.nft(configuration: .init(nft: $0)) }))
        }
    }
}

// MARK: - Activities Section
private extension DomainsCollectionCarouselItemViewPresenter {
    func addActivitiesSection(in snapshot: inout DomainsCollectionCarouselItemSnapshot, domain: DomainDisplayInfo) {
        if connectedApps.isEmpty {
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
            }, isTutorialOn: isTutorialOn))])
        } else {
            // Spacer
            if cardState == .expanded {
                snapshot.appendSections([.emptySeparator(height: emptySeparatorHeightForExpandedState())])
            }
            
            // Separator
            if !didShowSwipeDomainCardTutorial,
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
    }
}

// MARK: - Actions
private extension DomainsCollectionCarouselItemViewPresenter {
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
