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
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var currentIndex: Int { get }
    
    func canMove(to index: Int) -> Bool
    func domain(at index: Int) -> DomainDisplayInfo?
    func didMove(to index: Int)
    func didOccureUIAction(_ action: DomainsCollectionViewController.Action)
    func didTapSettingsButton()
    func importDomainsFromWebPressed()
    func didPressScanButton()
    func didMintDomains(result: MintDomainsNavigationController.MintDomainsResult)
    func didRecognizeQRCode()
    func didTapAddButton()
}

final class DomainsCollectionPresenter: ViewAnalyticsLogger {
    
    private weak var view: DomainsCollectionViewProtocol?
    private let router: DomainsCollectionRouterProtocol
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private let notificationsService: NotificationsServiceProtocol
    private let udWalletsService: UDWalletsServiceProtocol
    private var stateController: StateController = StateController()
    private(set) var isResolvingPrimaryDomain = false
    private var initialMintingState: DomainsCollectionMintingState
    private var shareDomainHandler: ShareDomainHandler?
    private(set) var currentIndex = 0

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
        updateUIControlsVisibility()
        Task {
            await loadInitialData()
            let domains = stateController.domains
            if let domain = domains.first {
                view?.setSelectedDomain(domain, at: 0, animated: false)
            }
            updateUI()
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
    
    func canMove(to index: Int) -> Bool {
        isIndexSupported(index)
    }
    
    func domain(at index: Int) -> DomainDisplayInfo? {
        guard isIndexSupported(index) else { return nil }
        
        return stateController.domains[index]
    }
   
    func didMove(to index: Int) {
        currentIndex = index
        updateUI()
    }
    
    func didOccureUIAction(_ action: DomainsCollectionViewController.Action) {
        switch action {
        case .emptyListItemType(let itemType):
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: itemType.analyticsName)
            switch itemType {
            case .importWallet:
                importWalletPressed()
            case .external:
                connectWalletPressed()
            }
        case .recentActivityLearnMore:
            logButtonPressedAnalyticEvents(button: .recentActivityLearnMore, parameters: [.domainName: getCurrentDomainName()])
            showRecentActivitiesLearMorePullUp()
        case .domainSelected(let domain):
            logAnalytic(event: .domainPressed, parameters: [.domainName : domain.name])
            UDVibration.buttonTap.vibrate()
            showDomainProfile(domain)
        case .mintingDomainSelected(let mintingDomain):
            logAnalytic(event: .mintingDomainPressed, parameters: [.domainName : mintingDomain.name])
            didSelectMintingDomain(mintingDomain)
        case .mintingDomainsShowMoreMintedDomainsPressed:
            logButtonPressedAnalyticEvents(button: .showMoreMintingDomains)
            showAllMintingInProgressList()
        case .rearrangeDomains:
            logButtonPressedAnalyticEvents(button: .rearrangeDomains)
            rearrangeDomains()
        case .searchPressed:
            logButtonPressedAnalyticEvents(button: .searchDomains)
            showDomainsSearch()
        }
    }

    func didTapSettingsButton() {
        UserDefaults.homeScreenSettingsButtonPressed = true
        updateGoToSettingsTutorialVisibility()
        router.showSettings(loginCallback: { [weak self] result in
            self?.handleLoginResult(result)
        })
    }

    @MainActor
    func importDomainsFromWebPressed() {
        runMintingFlow(mode: .default)
    }
     
    func didPressScanButton() {
        logButtonPressedAnalyticEvents(button: .scan, parameters: [.domainName: getCurrentDomainName()])
        showQRScanner()
    }
   
    func didMintDomains(result: MintDomainsNavigationController.MintDomainsResult) {
        switch result {
        case .noDomainsToMint:
            handleNoDomainsToMint()
        case .importWallet:
            router.showImportWalletsWith(initialAction: .showImportWalletOptionsPullUp)
        case .cancel:
            return
        case .minted, .skipped:
            let domains = stateController.domains
            guard let mintingDomainIndex = domains.firstIndex(where: { $0.isMinting }) else { return }
            
            setNewIndex(mintingDomainIndex, animated: true)
            updateUI()

            if case .minted = result,
               domains[mintingDomainIndex].isPrimary {
                view?.runConfettiAnimation()
                appContext.toastMessageService.showToast(.mintingSuccessful, isSticky: false)
            }
            AppReviewService.shared.appReviewEventDidOccurs(event: .didMintDomains)
        case .domainsPurchased(let details):
            Task {
                try? await Task.sleep(seconds: 0.2)
                router.runMintDomainsFlow(with: .domainsPurchased(details: details))
            }
        }
    }
    
    func didRecognizeQRCode() {
        guard let view = self.view else { return }
        
        if !(view.presentedViewController is PullUpViewController) {
            appContext.pullUpViewService.showLoadingIndicator(in: view)
        }
    }
    
    func didTapAddButton() {
        Task {
            guard let view = self.view,
                  await router.isMintingAvailable(in: view) else { return }
            
            do {
                let action = try await appContext.pullUpViewService.showMintDomainConfirmationPullUp(in: view)
                await view.dismissPullUpMenu()

                switch action {
                case .importFromWebsite:
                    importDomainsFromWebPressed()
                case .importWallet:
                    importWalletPressed()
                case .connectWallet:
                    connectWalletPressed()
                }
            }
        }
    }
}

// MARK: - AppLaunchServiceListener
extension DomainsCollectionPresenter: AppLaunchServiceListener {
    func appLaunchServiceDidUpdateAppVersion() {
        Task {
            let domains = await stateController.domains
            await resolvePrimaryDomain(domains: domains)
        }
    }
}

// MARK: - Private methods
private extension DomainsCollectionPresenter {
    func isPrimaryDomainSet(domains: [DomainDisplayInfo]) -> Bool {
        !(!domains.isEmpty && domains.first(where: { $0.isPrimary }) == nil)
    }
    
    @MainActor
    func isIndexSupported(_ index: Int) -> Bool {
        isIndexSupported(index, in: stateController.domains)
    }
    
    func isIndexSupported(_ index: Int, in domains: [DomainDisplayInfo]) -> Bool {
        index >= 0 && index < domains.count
    }
    
    func loadInitialData() async {
        let walletsWithInfo = await dataAggregatorService.getWalletsWithInfo()
        await stateController.set(walletsWithInfo: walletsWithInfo)
        let domains = await dataAggregatorService.getDomainsDisplayInfo()
        await setDomains(domains, shouldCheckPresentedDomains: true)
        
        if let _ = domains.first(where: { $0.isPrimary }) {
            switch initialMintingState {
            case .primaryDomainMinted:
                await view?.runConfettiAnimation()
            case .default, .mintingPrimary:
                return
            }
        } else {
            await resolvePrimaryDomain(domains: domains)
        }
    }
    
    func isPrimaryDomainResolved(domains: [DomainDisplayInfo]) -> Bool {
        let interactableDomains = domains.interactableItems()
        if !interactableDomains.isEmpty,
           interactableDomains.first(where: { $0.isPrimary }) == nil {
            return false
        }
        
        return true
    }
    
    @MainActor
    func resolvePrimaryDomain(domains: [DomainDisplayInfo]) async {
        if !isPrimaryDomainResolved(domains: domains),
           !isResolvingPrimaryDomain,
           router.isTopPresented() {
            guard let view = self.view else { return }
            
            self.isResolvingPrimaryDomain = true
            var domains = domains.interactableItems()
            
            ConfettiImageView.prepareAnimationsAsync()
            if domains.count == 1 {
                domains[0].setOrder(0)
                await updateDomainsListOrder(with: domains, newIndex: 0)
            } else {
                updateUI()
                let result = await UDRouter().showNewPrimaryDomainSelectionScreen(domains: domains,
                                                                                  isFirstPrimaryDomain: true,
                                                                                  configuration: .init(canReverseResolutionETHDomain: false,
                                                                                                       analyticsView: .sortDomainsForTheFirstTime),
                                                                                  in: view)
                switch result {
                case .cancelled:
                    Debugger.printFailure("Should not be able to dismiss initial home domain selection screen", critical: true)
                case .domainsOrderSet(let domains):
                    await updateDomainsListOrder(with: domains, newIndex: 0)
                case .domainsOrderAndReverseResolutionSet(let domains, let reverseResolutionDomain):
                    await updateDomainsListOrder(with: domains, newIndex: 0)
                    stateController.setReverseResolutionInProgressForDomain(reverseResolutionDomain)
                }
                domains = stateController.domains
                UserDefaults.setupRRPromptCounter = 1
            }
            updateUI()
            self.isResolvingPrimaryDomain = false
            view.runConfettiAnimation()
            notificationsService.checkNotificationsPermissions()
        }
    }
    
    @MainActor
    func updateDomainsListOrder(with domains: [DomainDisplayInfo], newIndex: Int?) async {
        stateController.set(domains: domains)
        if let newIndex {
            setNewIndex(newIndex)
        }
        await dataAggregatorService.setDomainsOrder(using: domains)
    }
    
    @MainActor
    func setNewIndex(_ newIndex: Int, animated: Bool = false) {
        guard isIndexSupported(newIndex) else {
            Debugger.printFailure("Attempt to set not supported index")
            return }
        let domains = stateController.domains
        currentIndex = newIndex
        view?.setSelectedDomain(domains[newIndex], at: newIndex, animated: animated)
    }
    
    @MainActor
    func rearrangeDomains() {
        Task {
            guard let view else { return }
            
            let domains = stateController.domains
            func updateDomains(_ updatedDomains: [DomainDisplayInfo]) async {
                let currentDomain = domains[self.currentIndex]
                let newIndex = updatedDomains.firstIndex(where: { $0.isSameEntity(currentDomain) })
                await updateDomainsListOrder(with: updatedDomains, newIndex: newIndex)
            }
            
            let result = await UDRouter().showNewPrimaryDomainSelectionScreen(domains: domains,
                                                                              isFirstPrimaryDomain: false,
                                                                              configuration: .init(canReverseResolutionETHDomain: false,
                                                                                                   analyticsView: .sortDomainsFromHome),
                                                                              in: view)
            switch result {
            case .cancelled:
                return
            case .domainsOrderSet(let domains):
                await updateDomains(domains)
            case .domainsOrderAndReverseResolutionSet(let domains, let reverseResolutionDomain):
                stateController.setReverseResolutionInProgressForDomain(reverseResolutionDomain)
                await updateDomains(domains)
            }
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
    
    func askToSetRRIfCurrentRRDomainIsNotPreferable(among domains: [DomainDisplayInfo]) async {
        let walletsWithInfo = await stateController.walletsWithInfo
        guard let preferableDomainNameForRR = UserDefaults.preferableDomainNameForRR,
              await router.isTopPresented(),
              let (index, preferableDomainForRR) = domains.enumerated().first(where: { $0.element.name == preferableDomainNameForRR }),
              !preferableDomainForRR.isMinting,
              let walletWithInfo = walletsWithInfo.first(where: { $0.wallet.owns(domain: preferableDomainForRR)}),
              let walletInfo = walletWithInfo.displayInfo else { return }
        
        guard walletInfo.reverseResolutionDomain?.name != preferableDomainNameForRR else {
            UserDefaults.preferableDomainNameForRR = nil
            return
        }
        
        await view?.setSelectedDomain(preferableDomainForRR, at: index, animated: true)
        try? await askToSetReverseResolutionFor(domain: preferableDomainForRR, in: walletInfo)
        UserDefaults.preferableDomainNameForRR = nil
    }
    
    func askToSetReverseResolutionFor(domain: DomainDisplayInfo, in walletInfo: WalletDisplayInfo) async throws {
        guard let view = self.view else { return }
        
        try await appContext.pullUpViewService.showSetupReverseResolutionPromptPullUp(walletInfo: walletInfo,
                                                                                  domain: domain,
                                                                                  in: view)
        await view.dismissPullUpMenu()
        try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
        let domain = try await dataAggregatorService.getDomainWith(name: domain.name)
        do {
            try await udWalletsService.setReverseResolution(to: domain,
                                                            paymentConfirmationDelegate: view)
            AppReviewService.shared.appReviewEventDidOccurs(event: .didSetRR)
        } catch {
            await MainActor.run {
                view.showAlertWith(error: error)
            }
            throw error 
        }
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
    func importWalletPressed() {
        router.showImportWalletsWith(initialAction: .importWallet)
    }
    
    @MainActor
    func connectWalletPressed() {
        router.showImportWalletsWith(initialAction: .connectWallet)
    }
    
    @MainActor
    func showDomainsSearch() {
        let domains = stateController.domains
        router.showDomainsSearch(domains) { [weak self] selectedDomain in
            self?.showDomain(selectedDomain, animated: false)
        }
    }
    
    func showDomain(_ domain: DomainDisplayInfo, animated: Bool = false) {
        Task { @MainActor in
            let domains = stateController.domains
            
            if let index = domains.firstIndex(where: { $0.isSameEntity(domain) }) {
                self.setNewIndex(index, animated: animated)
            }
        }
    }
    
    @MainActor
    func handleNoDomainsToMint() {
        didTapAddButton()
    }
    
    func handleLoginResult(_ result: LoginFlowNavigationController.LogInResult) {
        Task { @MainActor in
            switch result {
            case .loggedIn(let parkedDomains):
                guard let parkedDomain = parkedDomains.first else { return }
                
                view?.runConfettiAnimation()
                view?.showToast(.parkedDomainsImported(parkedDomains.count))
                let domains = stateController.domains
                if let domainIndex = domains.firstIndex(where: { $0.name == parkedDomain.name }) {
                    setNewIndex(domainIndex, animated: true)
                }
            case .failedToLoadParkedDomains, .cancel:
                return
            }
        }
    }
}
 
// MARK: - DataAggregatorServiceListener
extension DomainsCollectionPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task { @MainActor in
            switch result {
            case .success(let resultType):
                switch resultType {
                case .domainsUpdated(let domains):
                    setDomains(domains, shouldCheckPresentedDomains: true)
                    updateUI()
                    Task {
                        await resolvePrimaryDomain(domains: domains)
                        await askToSetRRIfCurrentRRDomainIsNotPreferable(among: domains)
                    }
                case .domainsPFPUpdated(let domains):
                    let isDomainsChanged = stateController.domains != domains
                    if isDomainsChanged {
                        setDomains(domains, shouldCheckPresentedDomains: false)
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

// MARK: - State & Representation methods
private extension DomainsCollectionPresenter {
    @MainActor
    func checkPresentedDomainsIndexChangedAndUpdateUI(newDomains: [DomainDisplayInfo]) {
        func updateSelectedDomain(_ domain: DomainDisplayInfo, at index: Int, newCurrentIndex: Int) {
            self.currentIndex = newCurrentIndex
            stateController.set(domains: newDomains)
            view?.setSelectedDomain(domain, at: index, animated: true)
        }
        
        guard isIndexSupported(currentIndex) else {
            if !newDomains.isEmpty {
                updateSelectedDomain(newDomains[0], at: 0, newCurrentIndex: 0)
            }
            return
        }
        
        let currentDomains = stateController.domains
        let currentlySelectedDomain = currentDomains[self.currentIndex]
        
        var didUpdateSelectedDomainIndex = false
        if let newIndex = newDomains.firstIndex(where: { $0.isSameEntity(currentlySelectedDomain )}) {
            /// Currently selected domain's order changed
            if newIndex != currentIndex {
                updateSelectedDomain(currentlySelectedDomain, at: newIndex, newCurrentIndex: newIndex)
                didUpdateSelectedDomainIndex = true
            }
        } else {
            /// Currently selected domain removed. Set first as current
            if !newDomains.isEmpty {
                updateSelectedDomain(newDomains[0], at: 0, newCurrentIndex: 0)
                didUpdateSelectedDomainIndex = true
            }
        }
        
        /// Check next and previous domain changed
        func isDomainIndexChanged(at index: Int) -> Bool {
            guard isIndexSupported(index, in: currentDomains) else {
                return isIndexSupported(index, in: newDomains) // If there's new index in new domains (usually when domains count goes from 1 to 2)
            }
            
            let currentDomains = currentDomains[index]
            let newIndex = newDomains.firstIndex(where: { $0.isSameEntity(currentDomains) })
            return newIndex != index
        }
        
        func isDomainsNextToCurrentChanged() -> Bool {
            isDomainIndexChanged(at: currentIndex - 1) || isDomainIndexChanged(at: currentIndex + 1)
        }
        
        /// If selected domain was updated before, it will automatically request new next and previous domain, no need extra steps.
        /// If selected domain wasn't updated, need to check if previous and next domain's order changed 
        if !didUpdateSelectedDomainIndex,
           isDomainsNextToCurrentChanged() {
            updateSelectedDomain(currentlySelectedDomain, at: currentIndex, newCurrentIndex: currentIndex)
        }
    }
    
    @MainActor
    func setDomains(_ domains: [DomainDisplayInfo], shouldCheckPresentedDomains: Bool) {
        if shouldCheckPresentedDomains {
            checkPresentedDomainsIndexChangedAndUpdateUI(newDomains: domains)
        }
        stateController.set(domains: domains)
        view?.setNumberOfSteps(domains.count)
        updateMintingDomainsUI()
    }
    
    @MainActor
    func updateUI() {
        updateBackgroundImage()
        updateGoToSettingsTutorialVisibility()
        updateUIControlsVisibility()
    }
    
    @MainActor
    func updateGoToSettingsTutorialVisibility() {
        view?.setGoToSettingsTutorialHidden(true) // Always hide for now (MOB-394)
    }
    
    @MainActor
    func updateUIControlsVisibility() {
        let isEmpty = stateController.domains.isEmpty
        view?.setScanButtonHidden(isEmpty)
        view?.setAddButtonHidden(isEmpty)
        view?.setEmptyState(hidden: !isEmpty)
    }
    
    @MainActor
    func updateBackgroundImage() {
        Task {
            let domains = stateController.domains
            if !domains.isEmpty {
                let domain = domains[currentIndex]
                let avatar = await appContext.imageLoadingService.loadImage(from: .domain(domain),
                                                                            downsampleDescription: nil)
                view?.setBackgroundImage(avatar)
            } else {
                view?.setBackgroundImage(nil)
            }
        }
    }
    
    @MainActor
    func updateMintingDomainsUI() {
        let mintingDomains: [DomainDisplayInfo]
        if Constants.isTestingMinting {
            mintingDomains = Array(stateController.domains.prefix(Constants.testMintingDomainsCount))
        } else {
            mintingDomains = stateController.domains.filter({ $0.isMinting })
        }
        view?.showMintingDomains(mintingDomains)
    }
    
    func showDomainProfile(_ domain: DomainDisplayInfo) {
        guard let view = self.view else { return }
        let topView = view.presentedViewController ?? view
        Task {
            switch domain.usageType {
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
                guard !domain.isMinting else {
                    await showDomainMintingInProgress(domain)
                    return }
                
                let walletsWithInfo = await stateController.walletsWithInfo
                guard let domainWallet = walletsWithInfo.first(where: { domain.isOwned(by: $0.wallet) })?.wallet,
                      let walletInfo = await dataAggregatorService.getWalletDisplayInfo(for: domainWallet) else { return }
                
                await router.showDomainProfile(domain, wallet: domainWallet, walletInfo: walletInfo, dismissCallback: { [weak self] in self?.didCloseDomainProfile(domain) })
            case .parked:
               try? await UDRouter().showDomainProfileParkedActionModule(in: view,
                                                                     domain: domain,
                                                                     imagesInfo: .init())
            }
        }
    }
    
    func didCloseDomainProfile(_ domain: DomainDisplayInfo) {
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
    func showDomainMintingInProgress(_ domain: DomainDisplayInfo) {
        guard domain.isMinting else { return }
        
        let mintingDomains = MintingDomainsStorage.retrieveMintingDomains()
        
        guard let mintingDomain = mintingDomains.first(where: { $0.name == domain.name }) else { return }
        
        let mintingDomainWithDisplayInfo = MintingDomainWithDisplayInfo(mintingDomain: mintingDomain,
                                                                        displayInfo: domain)
        showMintingInProgress(mintingDomainsWithDisplayInfo: [mintingDomainWithDisplayInfo])
    }
    
    @MainActor
    func showAllMintingInProgressList() {
        let domains = stateController.domains
        let mintingDomains: [MintingDomain]
        if Constants.isTestingMinting {
            let domainsToTransform = Array(stateController.domains.prefix(Constants.testMintingDomainsCount))
            mintingDomains = domainsToTransform.map({ MintingDomain(name: $0.name,
                                                                    walletAddress: $0.ownerWallet ?? "",
                                                                    isPrimary: false,
                                                                    transactionId: 0)})
        } else {
            mintingDomains = MintingDomainsStorage.retrieveMintingDomains()
        }
        
        let mintingDomainsWithDisplayInfo = mintingDomains.compactMap({ mintingDomain -> MintingDomainWithDisplayInfo? in
            guard let domain = domains.first(where: { $0.name == mintingDomain.name }) else { return nil }
            
            return MintingDomainWithDisplayInfo(mintingDomain: mintingDomain, displayInfo: domain)
        })
        
        showMintingInProgress(mintingDomainsWithDisplayInfo: mintingDomainsWithDisplayInfo)
    }
    
    @MainActor
    func showMintingInProgress(mintingDomainsWithDisplayInfo: [MintingDomainWithDisplayInfo]) {
        guard let view else { return }
        
        let vcToUse = view.presentedViewController ?? view
        UDRouter().showMintingDomainsInProgressScreen(mintingDomainsWithDisplayInfo: mintingDomainsWithDisplayInfo,
                                                      mintingDomainSelectedCallback: { [weak self] mintingDomain in
            self?.didSelectMintingDomain(mintingDomain)
        },
                                                      in: vcToUse)
    }
    
    func didSelectMintingDomain(_ mintingDomain: DomainDisplayInfo) {
        Task { @MainActor in
            let domains = stateController.domains
            guard let index = domains.firstIndex(where: { $0.isSameEntity(mintingDomain) }),
                  index != currentIndex else { return }
            
            setNewIndex(index, animated: true)
        }
    }
    
    @MainActor
    func runMintingFlow(mode: MintDomainsNavigationController.Mode) {
        router.runMintDomainsFlow(with: mode)
    }
    
    @MainActor
    func showRecentActivitiesLearMorePullUp() {
        Task {
            do {
                guard let view = self.view else { return }
                
                try await appContext.pullUpViewService.showRecentActivitiesInfoPullUp(in: view)
                await view.dismissPullUpMenu()
                showQRScanner()
            }
        }
    }
    
    @MainActor
    func showQRScanner() {
        guard isIndexSupported(currentIndex) else { return }
        
        let domains = stateController.domains
        let selectedDomain = domains[currentIndex]
        router.showQRScanner(selectedDomain: selectedDomain)
    }
    
    @MainActor
    func getCurrentDomain() -> DomainDisplayInfo? {
        guard isIndexSupported(currentIndex) else { return nil }
        return stateController.domains[currentIndex]
    }
    
    @MainActor
    func getCurrentDomainName() -> String {
        getCurrentDomain()?.name ?? "N/A"
    }
    
}

// MARK: - State
extension DomainsCollectionPresenter {
    @MainActor
    final class StateController {
        var domains = [DomainDisplayInfo]()
        var walletsWithInfo = [WalletWithInfo]()

        nonisolated
        init() { }
        
        func set(domains: [DomainDisplayInfo]) {
            self.domains = domains
        }
        
        func set(walletsWithInfo: [WalletWithInfo]) {
            self.walletsWithInfo = walletsWithInfo
        }
        
        func setReverseResolutionInProgressForDomain(_ newRRDomain: DomainDisplayInfo) {
            if let i = domains.firstIndex(where: { $0.name == newRRDomain.name }) {
                domains[i].setState(.updatingRecords)
            }
        }
    }
}

enum MintDomainPullUpAction: String, CaseIterable, PullUpCollectionViewCellItem {
    case importWallet, connectWallet, importFromWebsite
    
    var title: String {
        switch self {
        case .importFromWebsite:
            return String.Constants.importFromTheWebsite.localized()
        case .importWallet:
            return String.Constants.connectWalletRecovery.localized()
        case .connectWallet:
            return String.Constants.connectWalletExternal.localized()
        }
    }
    
    var subtitle: String? {
        switch self {
        case .importFromWebsite:
            return String.Constants.storeInYourDomainVault.localized()
        case .importWallet:
            return nil
        case .connectWallet:
            return String.Constants.domainsCollectionEmptyStateExternalSubtitle.localized()
        }
    }
    
    var icon: UIImage {
        switch self {
        case .importFromWebsite:
            return .sparklesIcon
        case .importWallet:
            return .recoveryPhraseIcon
        case .connectWallet:
            return .externalWalletIndicator
        }
    }
    
    var analyticsName: String { rawValue }
    
}

enum DomainsCollectionMintingState {
    case `default`, mintingPrimary, primaryDomainMinted
}
