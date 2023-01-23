//
//  DomainsCollectionPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import Foundation
import UIKit

@MainActor
protocol DomainsCollectionPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }
    var scrollableContentYOffset: CGFloat { get }
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    
    func didSelectItem(_ item: DomainsCollectionViewController.Item)
    func didChangeDomainsVisualisation(_ domainsVisualisation: DomainsCollectionViewController.DomainsVisualisation)
    func didTapSettingsButton()
    func didTapAddButton()
    func didPressScanButton()
    func didSearchDomainsWith(key: String)
    func didMintDomains(result: MintDomainsNavigationController.MintDomainsResult)
    func didStartSearch()
    func didStopSearch()
    func didRecognizeQRCode()
}

final class DomainsCollectionPresenter: ViewAnalyticsLogger {
    
    private weak var view: DomainsCollectionViewProtocol?
    private let router: DomainsCollectionRouterProtocol
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private let notificationsService: NotificationsServiceProtocol
    private let udWalletsService: UDWalletsServiceProtocol
    private var stateController: StateController = StateController()
    private var transactions = [TransactionItem]()
    private var updateTimer: Timer?
    private var searchKey = ""
    private var isSearchActive = false
    private(set) var isResolvingPrimaryDomain = false
    private var initialMintingState: DomainsCollectionMintingState
    private var shareDomainHandler: ShareDomainHandler?
    var scrollableContentYOffset: CGFloat { 16 }
    var analyticsName: Analytics.ViewName { .home }
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    
    init(view: DomainsCollectionViewProtocol,
         router: DomainsCollectionRouterProtocol,
         dataAggregatorService: DataAggregatorServiceProtocol,
         initialMintingState: DomainsCollectionMintingState,
         notificationsService: NotificationsServiceProtocol,
         udWalletsService: UDWalletsServiceProtocol,
         appLaunchService: AppLaunchServiceProtocol) {
        self.view = view
        self.router = router
        self.dataAggregatorService = dataAggregatorService
        self.initialMintingState = initialMintingState
        self.notificationsService = notificationsService
        self.udWalletsService = udWalletsService
        appLaunchService.addListener(self)
    }
    
}

// MARK: - DomainsCollectionPresenterProtocol
extension DomainsCollectionPresenter: DomainsCollectionPresenterProtocol {
    @MainActor
    func viewDidLoad() {
        dataAggregatorService.addListener(self)
        view?.setSettingsButtonHidden(false)
        updateGoToSettingsTutorialVisibility()
        Task {
            await loadInitialData()
            let domains = stateController.domains
            resolveCurrentState(animated: false, domains: domains)
            await resolvePrimaryDomain(domains: domains)
            launchMintFlowAfterOnboardingIfNeeded()
            await showReverseResolutionPromptIfNeeded()
        }
    }
    
    func viewDidAppear() {
        Task {
            let domains = await stateController.domains
            await resolvePrimaryDomain(domains: domains)
            await askToSetRRIfCurrentRRDomainIsNotPreferable(among: domains)
        }
    }
    
    func didSelectItem(_ item: DomainsCollectionViewController.Item) {
        switch item {
        case .empty, .searchEmptyState, .emptyTopInfo:
            return
        case .emptyList(let itemType):
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: itemType.analyticsName)
            switch itemType {
            case .mintDomains:
                mintDomainPressed()
            case .buyDomains:
                buyDomainPressed()
            case .manageDomains:
                manageDomainsPressed()
            }
        case .domainCardItem(let displayInfo):
            let domainItem = displayInfo.domainItem
            logAnalytic(event: .domainPressed, parameters: [.domainName : domainItem.name,
                                                            .topControlType : DomainsCollectionViewController.DomainsVisualisation.card.analyticsName])
            UDVibration.buttonTap.vibrate()
            if !UserDefaults.didTapPrimaryDomain {
                UserDefaults.didTapPrimaryDomain = true
                let domains = stateController.domains
                let state = stateController.state
                setState(state, domains: domains, animated: false)
            }
            showDomainProfile(domainItem)
        case .domainListItem(let domainItem, _, _, _):
            logAnalytic(event: .domainPressed, parameters: [.domainName : domainItem.name,
                                                            .topControlType : DomainsCollectionViewController.DomainsVisualisation.list.analyticsName])
            UDVibration.buttonTap.vibrate()
            showDomainProfile(domainItem)
        case .domainsMintingInProgress:
            logAnalytic(event: .mintingDomainsPressed)
            UDVibration.buttonTap.vibrate()
            let domains = stateController.domains
            showMintingInProgressList(domains.filter({ $0.isMinting }))
        }
    }
    
    func didChangeDomainsVisualisation(_ domainsVisualisation: DomainsCollectionViewController.DomainsVisualisation) {
        let domains = stateController.domains
        switch domainsVisualisation {
        case .card:
            setState(cardState(domains: domains), domains: domains, animated: true)
        case .list:
            setState(listState(domains: domains), domains: domains, animated: true)
        }
    }
    
    func didTapSettingsButton() {
        UserDefaults.homeScreenSettingsButtonPressed = true
        updateGoToSettingsTutorialVisibility()
        router.showSettings()
    }
    
    func didTapAddButton() {
        Task {
            guard let view = self.view,
                await router.isMintingAvailable(in: view) else { return }
            
            do {
                let action = try await appContext.pullUpViewService.showMintDomainConfirmationPullUp(in: view)
                switch action {
                case .mint:
                    mintDomainPressed()
                case .importWallet:
                    await view.dismissPullUpMenu()
                    router.showImportWalletsOptions()
                }
            }
        }
    }
    
    func didPressScanButton() {
        router.showQRScanner()
    }
    
    func didSearchDomainsWith(key: String) {
        logAnalytic(event: .didSearch, parameters: [.domainName: key])
        let representation = stateController.representation
        self.searchKey = key
        guard let representation = representation as? DomainsCollectionListRepresentation else { return }
        
        let domains = stateController.domains
        representation.domains = self.domainsForCurrentState(domains: domains)
        view?.applySnapshot(representation.snapshot(), animated: true)
    }
    
    func didMintDomains(result: MintDomainsNavigationController.MintDomainsResult) {
        switch result {
        case .noDomainsToMint:
            didTapAddButton()
        case .importWallet:
            router.showImportWalletsOptions()
        case .cancel:
            return
        case .minted(let isPrimary):
            let domains = stateController.domains
            if isPrimary {
                setState(cardState(domains: domains), domains: domains, animated: true)
                view?.runConfettiAnimation()
                appContext.toastMessageService.showToast(.mintingSuccessful, isSticky: false)
                
            } else {
                setState(listState(domains: domains), domains: domains, animated: true)
            }
            
        case .domainsPurchased(let details):
            Task {
                try? await Task.sleep(seconds: 0.2)
                router.runMintDomainsFlow(with: .domainsPurchased(details: details))
            }
        }
    }
        
    func didStartSearch() {
        logAnalytic(event: .didStartSearching)
        let representation = stateController.representation
        self.isSearchActive = true
        guard let representation = representation as? DomainsCollectionListRepresentation else { return }
        
        representation.isSearchActive = true
        representation.domains = []
        view?.applySnapshot(representation.snapshot(), animated: false)
    }
    
    func didStopSearch() {
        logAnalytic(event: .didStopSearching)
        let representation = stateController.representation
        let domains = stateController.domains
        self.isSearchActive = false
        guard let representation = representation as? DomainsCollectionListRepresentation else { return }
        
        representation.isSearchActive = false
        representation.domains = domains
        view?.applySnapshot(representation.snapshot(), animated: false)
    }
    
    func didRecognizeQRCode() {
        guard let view = self.view else { return }
        
        if !(view.presentedViewController is PullUpViewController) {
            appContext.pullUpViewService.showLoadingIndicator(in: view)
        }
    }
}


// MARK: - AppLaunchServiceListener
extension DomainsCollectionPresenter: AppLaunchServiceListener {
    func appLaunchServiceDidUpdateAppVersion() {
        Task { @MainActor in
            let domains = stateController.domains
            resolveCurrentState(animated: true, domains: domains)
            await resolvePrimaryDomain(domains: domains)
        }
    }
}

// MARK: - Private methods
private extension DomainsCollectionPresenter {
    func isPrimaryDomainSet(domains: [DomainItem]) -> Bool {
        !(!domains.isEmpty && domains.first(where: { $0.isPrimary }) == nil)
    }
    
    func loadInitialData() async {
        let walletsWithInfo = await dataAggregatorService.getWalletsWithInfo()
        await stateController.set(walletsWithInfo: walletsWithInfo)
        let domains = await dataAggregatorService.getDomains()
        await stateController.set(domains: domains)
       
        if let _ = domains.first(where: { $0.isPrimary }) {
            switch initialMintingState {
            case .mintingPrimary:
                await runMintingFlow(mode: .mintingInProgress(domains: MintingDomainsStorage.retrieveMintingDomains()))
            case .primaryDomainMinted:
                await view?.runConfettiAnimation()
            case .default:
                return
            }
        } else {
            await resolvePrimaryDomain(domains: domains)
        }
    }
    
    func isPrimaryDomainResolved(domains: [DomainItem]) -> Bool {
        let interactableDomains = domains.interactableItems()
        if !interactableDomains.isEmpty,
           interactableDomains.first(where: { $0.isPrimary }) == nil {
            return false
        }
        
        return true
    }
    
    @MainActor
    func resolvePrimaryDomain(domains: [DomainItem]) async {
        func updatePrimaryDomain(with newPrimaryDomain: DomainItem) async {
            await dataAggregatorService.setPrimaryDomainWith(name: newPrimaryDomain.name)
            stateController.updatePrimaryDomain(newPrimaryDomain)
        }
        
        if !isPrimaryDomainResolved(domains: domains),
           !isResolvingPrimaryDomain,
           router.isTopPresented() {
            guard let view = self.view else { return }
            
            self.isResolvingPrimaryDomain = true
            var domains = domains.interactableItems()
            
            ConfettiImageView.prepareAnimationsAsync()
            if domains.count == 1 {
                await dataAggregatorService.setPrimaryDomainWith(name: domains[0].name)
            } else {
                setState(listState(domains: domains), domains: domains, animated: true)
                let result = await UDRouter().showNewPrimaryDomainSelectionScreen(domains: domains,
                                                                                  isFirstPrimaryDomain: true,
                                                                                  configuration: .init(canReverseResolutionETHDomain: false,
                                                                                                       analyticsView: .chooseFirstPrimaryDomain),
                                                                                  in: view)
                switch result {
                case .cancelled:
                    Debugger.printFailure("Should not be able to dismiss initial home domain selection screen", critical: true)
                case .homeDomainSet(let newPrimaryDomain):
                    await updatePrimaryDomain(with: newPrimaryDomain)
                case .homeAndReverseResolutionSet(let newPrimaryDomain):
                    await updatePrimaryDomain(with: newPrimaryDomain)
                    stateController.setReverseResolutionInProgressForDomain(newPrimaryDomain)
                }
                domains = stateController.domains
                UserDefaults.setupRRPromptCounter = 1
            }
            setState(cardState(domains: domains), domains: domains, animated: true)
            self.isResolvingPrimaryDomain = false
            view.runConfettiAnimation()
            notificationsService.checkNotificationsPermissions()
        }
    }
    
    func showReverseResolutionPromptIfNeeded() async {
        do {
            let domains = await stateController.domains
            let walletsWithInfo = await stateController.walletsWithInfo
            guard let primary = domains.first(where: { $0.isPrimary }),
                  primary.isInteractable,
                  let walletWithInfo = walletsWithInfo.first(where: { primary.isOwned(by: $0.wallet ) }),
                  let walletInfo = walletWithInfo.displayInfo,
                  walletInfo.reverseResolutionDomain == nil,
                  (await dataAggregatorService.isReverseResolutionChangeAllowed(for: primary)) else {
                return }
            
            if UserDefaults.setupRRPromptCounter == 0 ||
                UserDefaults.setupRRPromptCounter >= Constants.setupRRPromptRepeatInterval {
                try await askToSetReverseResolutionFor(domain: primary, in: walletInfo)
                UserDefaults.setupRRPromptCounter = 0
            } else {
                UserDefaults.setupRRPromptCounter += 1
            }
        } catch AuthentificationError.cancelled {
            await showReverseResolutionPromptIfNeeded()
        } catch {
            UserDefaults.setupRRPromptCounter = 1
        }
    }
    
    func askToSetRRIfCurrentRRDomainIsNotPreferable(among domains: [DomainItem]) async {
        let walletsWithInfo = await stateController.walletsWithInfo
        if let preferableDomainNameForRR = UserDefaults.preferableDomainNameForRR,
           let primaryDomain = domains.first(where: { $0.isPrimary }),
           preferableDomainNameForRR == primaryDomain.name,
           let walletWithInfo = walletsWithInfo.first(where: { $0.wallet.owns(domain: primaryDomain)}),
           let walletInfo = walletWithInfo.displayInfo {
            guard let rrDomain = walletInfo.reverseResolutionDomain else { return }
            
            if rrDomain.name != preferableDomainNameForRR {
                try? await askToSetReverseResolutionFor(domain: primaryDomain, in: walletInfo)
            }
            
            UserDefaults.preferableDomainNameForRR = nil
        }
    }
    
    func askToSetReverseResolutionFor(domain: DomainItem, in walletInfo: WalletDisplayInfo) async throws {
        guard let view = self.view else { return }
        
        try await appContext.pullUpViewService.showSetupReverseResolutionPromptPullUp(walletInfo: walletInfo,
                                                                                  domain: domain,
                                                                                  in: view)
        await view.dismissPullUpMenu()
        try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
        do {
            try await udWalletsService.setReverseResolution(to: domain,
                                                            paymentConfirmationDelegate: view)
        } catch {
            await MainActor.run {
                view.showAlertWith(error: error)
            }
            throw error 
        }
    }
    
    @MainActor
    func resolveCurrentState(animated: Bool, domains: [DomainItem]) {
        let state = stateController.state
        if domains.isEmpty {
            setState(.empty, domains: [], animated: animated)
        } else {
            if case .list = state,
               domains.count > 1 {
                setState(listState(domains: domains), domains: domains, animated: animated)
            } else {
                setState(cardState(domains: domains), domains: domains, animated: animated)
            }
        }
    }
    
    func cardState(domains: [DomainItem]) -> State {
        guard !domains.isEmpty else { return .empty }
        
        let cardDomain = domains.first(where: { $0.isPrimary == true }) ?? domains.first!
        return .card(domain: cardDomain)
    }
    
    func listState(domains: [DomainItem]) -> State {
        guard !domains.isEmpty else { return .empty }
        
        return .list(domains: domainsForCurrentState(domains: domains))
    }
    
    @MainActor
    func mintDomainPressed() {
        runMintingFlow(mode: .default)
    }
    
    @MainActor
    func buyDomainPressed() {
        router.showBuyDomainsWebView()
    }
    
    @MainActor
    func launchMintFlowAfterOnboardingIfNeeded() {
        if let details = UserDefaults.onboardingDomainsPurchasedDetails {
            runMintingFlow(mode: .domainsPurchased(details: details))
            UserDefaults.onboardingDomainsPurchasedDetails = nil
        }
    }
    
    @MainActor
    func manageDomainsPressed() {
        router.showImportWalletsOptions()
    }
}

// MARK: - DataAggregatorServiceListener
extension DomainsCollectionPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task {
            await MainActor.run {
                switch result {
                case .success(let resultType):
                    switch resultType {
                    case .domainsUpdated(let domains):
                        let isDomainsChanged = stateController.domains != domains
                                                
                        self.stateController.set(domains: domains)
                        if !isResolvingPrimaryDomain {
                            if isPrimaryDomainResolved(domains: domains) {
                                if isDomainsChanged {
                                    resolveCurrentState(animated: true, domains: domains)
                                }
                            } else {
                                Task {
                                    await resolvePrimaryDomain(domains: domains)
                                }
                            }
                        }
                    case .domainsPFPUpdated(let domains):
                        let isDomainsChanged = stateController.domains != domains
                        if isDomainsChanged {
                            self.stateController.set(domains: domains)
                            resolveCurrentState(animated: false, domains: domains)
                        }
                    case .walletsListUpdated(let wallets):
                        stateController.set(walletsWithInfo: wallets)
                        if wallets.isEmpty {
                            SceneDelegate.shared?.restartOnboarding()
                        }
                    case .primaryDomainChanged: return
                    }
                case .failure:
                    return
                }
            }
        }
    }
}

// MARK: - State & Representation methods
private extension DomainsCollectionPresenter {
    @MainActor
    func setState(_ state: State, domains: [DomainItem], animated: Bool) {
        stateController.set(state: state)
        let newRepresentation = stateController.representation(for: state, isSearchActive: isSearchActive)
        let currentRepresentation = stateController.representation
        setRepresentation(newRepresentation, currentRepresentation: currentRepresentation, animated: animated)
        updateBackgroundImage(domains: domains, state: state)
        updateGoToSettingsTutorialVisibility()
        updateUIControlsVisibility(domains: domains, state: state)
        stateController.set(representation: newRepresentation)
    }
    
    func domainsForCurrentState(domains: [DomainItem]) -> [DomainItem] {
        if isSearchActive {
            if searchKey.isEmpty {
                return []
            } else {
                return domains.filter({ $0.name.lowercased().contains(searchKey.lowercased()) })
            }
        } else {
            return domains
        }
    }
    
    @MainActor
    func setRepresentation(_ newRepresentation: DomainsCollectionRepresentation, currentRepresentation: DomainsCollectionRepresentation?, animated: Bool) {
        view?.setScrollEnabled(newRepresentation.isScrollEnabled)
        if type(of: currentRepresentation) != type(of: newRepresentation) {
            let layout = newRepresentation.layout()
            view?.setLayout(layout)
        }
        if animated { // Avoid auto-transition which looks ugly.
            view?.applySnapshot(.init(), animated: false)
        }
        let snapshot = newRepresentation.snapshot()
        view?.applySnapshot(snapshot, animated: animated)
    }
    
    @MainActor
    func updateGoToSettingsTutorialVisibility() {
        view?.setGoToSettingsTutorialHidden(true) // Always hide for now (MOB-394)
    }
    
    @MainActor
    func updateUIControlsVisibility(domains: [DomainItem], state: State) {
        view?.setVisualisationControlHidden(domains.count <= 1)
        if case .list = state {
            view?.setVisualisationControlSelectedSegmentIndex(1)
        } else {
            view?.setVisualisationControlSelectedSegmentIndex(0)
        }
        view?.setScanButtonHidden(domains.isEmpty)
        
        switch state {
        case .empty:
            view?.setAddButtonHidden(true)
            view?.setEmptyState(hidden: false)
        case .list, .card:
            view?.setAddButtonHidden(false)
            view?.setEmptyState(hidden: true)
        }
    }
    
    @MainActor
    func updateBackgroundImage(domains: [DomainItem], state: State) {
        if case .card = state,
           let domain = domains.first(where: { $0.isPrimary == true }) ?? domains.first {
            Task {
                let avatar = await appContext.imageLoadingService.loadImage(from: .domain(domain),
                                                                            downsampleDescription: nil)
                view?.setBackgroundImage(avatar)
            }
        } else {
            view?.setBackgroundImage(nil)
        }
    }
    
    func showDomainProfile(_ domainItem: DomainItem) {
        guard let view = self.view else { return }
        let topView = view.presentedViewController ?? view
        Task {
            switch domainItem.usageType {
            case .zil:
                do {
                    try await appContext.pullUpViewService.showZilDomainsNotSupportedPullUp(in: topView)
                    await topView.dismissPullUpMenu()
                    await UDRouter().showUpgradeToPolygonTutorialScreen(in: topView)
                }
            case .deprecated(let tld):
                do {
                    try await appContext.pullUpViewService.showDomainTLDDeprecatedPullUp(tld: tld, in: topView)
                    await topView.dismissPullUpMenu()
                    await topView.openLink(.deprecatedCoinTLDPage)
                }
            case .normal:
                let walletsWithInfo = await stateController.walletsWithInfo
                guard let domainWallet = walletsWithInfo.first(where: { domainItem.isOwned(by: $0.wallet) })?.wallet,
                      let walletInfo = await dataAggregatorService.getWalletDisplayInfo(for: domainWallet) else { return }
                
                await router.showDomainProfile(domainItem, wallet: domainWallet, walletInfo: walletInfo, dismissCallback: { [weak self] in self?.didCloseDomainProfile(domainItem) })
            }
        }
    }
    
    func didCloseDomainProfile(_ domain: DomainItem) {
        if !UserDefaults.didAskToShowcaseProfileAfterFirstUpdate,
           UserDefaults.didEverUpdateDomainProfile {
            guard let view = self.view else { return }
            
            UserDefaults.didAskToShowcaseProfileAfterFirstUpdate = true
            Task {
                do {
                    try await appContext.pullUpViewService.showShowcaseYourProfilePullUp(for: domain,
                                                                                         in: view)
                    await view.dismissPullUpMenu()
                    
                    shareDomainHandler = ShareDomainHandler(domain: domain)
                    shareDomainHandler?.shareDomainInfo(in: view,
                                                        analyticsLogger: self)
                }
            }
        }
    }
    
    @MainActor
    func showMintingInProgressList(_ domainItems: [DomainItem]) {
        guard let view = self.view else { return }
        
        let vcToUse = view.presentedViewController ?? view
        UDRouter().showMintingDomainsInProgressScreen(domains: domainItems, in: vcToUse)
    }
    
    @MainActor
    func runMintingFlow(mode: MintDomainsNavigationController.Mode) {
        router.runMintDomainsFlow(with: mode)
    }
}

// MARK: - State
extension DomainsCollectionPresenter {
    enum State {
        case empty, card(domain: DomainItem), list(domains: [DomainItem])
    }
    
    @MainActor
    final class StateController {
        var state: State = .empty
        var representation: DomainsCollectionRepresentation? = nil
        var domains = [DomainItem]()
        var walletsWithInfo = [WalletWithInfo]()

        private var emptyRepresentation: DomainsCollectionEmptyListRepresentation?
        private var cardRepresentation: DomainsCollectionCardRepresentation?
        private var listRepresentation: DomainsCollectionListRepresentation?
        
        nonisolated
        init() { }
        
        func set(state: State) {
            self.state = state
        }
        
        func set(representation: DomainsCollectionRepresentation) {
            self.representation = representation
        }
        
        func set(domains: [DomainItem]) {
            self.domains = domains
        }
        
        func set(walletsWithInfo: [WalletWithInfo]) {
            self.walletsWithInfo = walletsWithInfo
        }
        
        func updatePrimaryDomain(_ newPrimaryDomain: DomainItem) {
            if let i = domains.firstIndex(where: { $0.name == newPrimaryDomain.name }) {
                domains[i].isPrimary = true
            }
        }
        
        func setReverseResolutionInProgressForDomain(_ newRRDomain: DomainItem) {
            if let i = domains.firstIndex(where: { $0.name == newRRDomain.name }) {
                domains[i].isUpdatingRecords = true
            }
        }
        
        func representation(for state: State, isSearchActive: Bool) -> DomainsCollectionRepresentation {
            switch state {
            case .empty:
                if let emptyRepresentation = self.emptyRepresentation {
                    return emptyRepresentation
                }
                let emptyRepresentation = DomainsCollectionEmptyListRepresentation()
                self.emptyRepresentation = emptyRepresentation
                return emptyRepresentation
            case .card(let domain):
                if let cardRepresentation = self.cardRepresentation {
                    cardRepresentation.domain = domain
                    return cardRepresentation
                }
                let cardRepresentation = DomainsCollectionCardRepresentation(domain: domain)
                self.cardRepresentation = cardRepresentation
                return cardRepresentation
            case .list(let domains):
                if let listRepresentation = self.listRepresentation {
                    listRepresentation.domains = domains
                    listRepresentation.isSearchActive = isSearchActive
                    return listRepresentation
                }
                let reverseResolutionDomains = walletsWithInfo.compactMap({ $0.displayInfo?.reverseResolutionDomain })
                let listRepresentation = DomainsCollectionListRepresentation(domains: domains,
                                                                             reverseResolutionDomains: reverseResolutionDomains,
                                                                             isSearchActive: isSearchActive)
                self.listRepresentation = listRepresentation
                return listRepresentation
            }
        }
    }
}

enum MintDomainPullUpAction {
    case mint, importWallet
}

enum DomainsCollectionMintingState {
    case `default`, mintingPrimary, primaryDomainMinted
}
