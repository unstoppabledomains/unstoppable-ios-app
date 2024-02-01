//
//  AppLaunchService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.06.2022.
//

import Foundation

final class AppLaunchService {
        
    private let maximumWaitingTime: TimeInterval = 1.0
    private var stateMachine = InitialMintingStateMachine()
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private let coreAppCoordinator: CoreAppCoordinatorProtocol
    private let udWalletsService: UDWalletsServiceProtocol
    private var sceneDelegate: SceneDelegateProtocol?
    private var completion: EmptyAsyncCallback?
    private var listeners: [AppLaunchListenerHolder] = []

    init(dataAggregatorService: DataAggregatorServiceProtocol,
         coreAppCoordinator: CoreAppCoordinatorProtocol,
         udWalletsService: UDWalletsServiceProtocol) {
        self.dataAggregatorService = dataAggregatorService
        self.coreAppCoordinator = coreAppCoordinator
        self.udWalletsService = udWalletsService
    }
    
}

// MARK: - AppLaunchServiceProtocol
extension AppLaunchService: AppLaunchServiceProtocol {
    func startWith(sceneDelegate: SceneDelegateProtocol,
                   walletConnectServiceV2: WalletConnectServiceV2Protocol,
                   completion: @escaping EmptyAsyncCallback) {
        self.sceneDelegate = sceneDelegate
        self.completion = completion
        checkFirstLaunchAfterGIFSupportReleased()
        resolveInitialViewController()
        wakeUpServices(walletConnectServiceV2: walletConnectServiceV2)
        preparePopularPlaceholders()
    }
    
    func addListener(_ listener: AppLaunchServiceListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: AppLaunchServiceListener) {
        listeners.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - Private methods
private extension AppLaunchService {
    func resolveInitialViewController() {
        let startTime = Date()
        Task {
            do {
                try await initialWalletsCheck()
                
                let appVersion = User.instance.getAppVersionInfo()
                await appVersionUpdated(appVersion)
                
                let onboardingDone = User.instance.getSettings().onboardingDone ?? false
                let shouldRunOnboarding: Bool
                let sessionState = AppSessionInterpreter.shared.state()
                switch sessionState {
                case .noWalletsOrWebAccount, .webAccountWithoutParkedDomains:
                    shouldRunOnboarding = true
                    appContext.firebaseParkedDomainsAuthenticationService.logout()
                case .walletAdded, .webAccountWithParkedDomains:
                    shouldRunOnboarding = false
                }
                
                if shouldRunOnboarding || !onboardingDone {
                    let wallets = udWalletsService.getUserWallets()
                    let onboardingFlow: OnboardingNavigationController.OnboardingFlow
                    
                    if wallets.isEmpty {
                        onboardingFlow = .newUser(subFlow: nil)
                    } else {
                        Task.detached { [weak self] in
                            await self?.dataAggregatorService.aggregateData(shouldRefreshPFP: true)
                        }
                        onboardingFlow = .existingUser(wallets: wallets)
                    }
                    
                    await coreAppCoordinator.showOnboarding(onboardingFlow)
                    Task.detached(priority: .background) { [unowned self] in
                        try? await sceneDelegate?.authorizeUserOnAppOpening()
                    }
                    completion?()
                } else {
                    resolveInitialMintingState(startTime: startTime, 
                                               sessionState: sessionState)
                }
            } catch {
                Debugger.printFailure("Failed to migrate legacy wallets", critical: true)
                await MainActor.run {
                    sceneDelegate?.window?.rootViewController?.showSimpleAlert(title: "Failed to re-organize wallets",
                                                                               body: "The storage of wallets has failed to re-organize. Please send a message to support at mobile@unstoppabledomains.com")
                }
            }
        }
    }
    
    func initialWalletsCheck() async throws {
        try await UDWalletsStorage.instance.initialWalletsCheck()
    }
     
    func resolveInitialMintingState(startTime: Date,
                                    sessionState: AppSessionInterpreter.State) {
        let mintingDomains = MintingDomainsStorage.retrieveMintingDomains()

        Task.detached(priority: .medium) { [weak self] in
            guard let self else { return }
            
            let appVersion = await appContext.userDataService.getLatestAppVersion()
            appContext.coinRecordsService.refreshCurrencies(version: appVersion.mobileUnsReleaseVersion ?? Constants.defaultUNSReleaseVersion)
            await self.appVersionUpdated(appVersion)
            await self.stateMachine.set(appVersionInfo: appVersion)
            
            let state = await self.stateMachine.state
            
            switch state {
            case .dataLoadedLate, .dataLoadedInTime, .maxIntervalPassed:
                if !self.isAppVersionSupported(info: appVersion) {
                    await self.coreAppCoordinator.showAppUpdateRequired()
                } else {
                    self.listeners.forEach { holder in
                        holder.listener?.appLaunchServiceDidUpdateAppVersion()
                    }
                }
            case .loading:
                return
            }
        }
        
        Task.detached(priority: .background) { [weak self] in
            await Task.sleep(seconds: 0.05)
            guard let self else { return }
            try? await self.sceneDelegate?.authorizeUserOnAppOpening()
            await self.handleInitialState(await self.stateMachine.stateAfter(event: .didAuthorise),
                                          sessionState: sessionState)
        }

        Task {
            await dataAggregatorService.aggregateData(shouldRefreshPFP: true)
//            let domains = await dataAggregatorService.getDomainsDisplayInfo()
//            let mintingState = await mintingStateFor(domains: domains, mintingDomains: mintingDomains)
            await handleInitialState(await stateMachine.stateAfter(event: .didLoadData(mintingState: .default)),
                                     sessionState: sessionState)
        }
        
        Task {
//            let domains = await dataAggregatorService.getDomainsDisplayInfo()
            let timePassed = Date().timeIntervalSince(startTime)
            let timeLeft: TimeInterval = max(0, maximumWaitingTime - timePassed)
            await Task.sleep(seconds: timeLeft)

//            let mintingState = await mintingStateFor(domains: domains, mintingDomains: .default)
            await handleInitialState(await stateMachine.stateAfter(event: .didPassMaxWaitingTime(preliminaryMintingState: .default)),
                                     sessionState: sessionState)
        }
    }
    
    func mintingStateFor(domains: [DomainDisplayInfo], mintingDomains: [MintingDomain]) async -> DomainsCollectionMintingState {
        if domains.first(where: { $0.isPrimary })?.state == .minting {
            await ConfettiImageView.prepareAnimationsAsync()
            return .mintingPrimary
        } else {
            if mintingDomains.first(where: { $0.isPrimary }) == nil {
                return .default
            } else {
                await ConfettiImageView.prepareAnimationsAsync()
                return .primaryDomainMinted
            }
        }
    }
    
    @MainActor
    func handleInitialState(_ state: InitialMintingStateMachine.State?,
                            sessionState: AppSessionInterpreter.State) async {
        guard let state = state else { return }
        
        switch state {
        case .loading:
            return
        case .maxIntervalPassed(let mintingState), .dataLoadedInTime(let mintingState):
            if let newAppVersionInfo = await stateMachine.appVersionInfo,
               !isAppVersionSupported(info: newAppVersionInfo) {
                coreAppCoordinator.showAppUpdateRequired()
            } else { // TODO: - Refactoring
                switch sessionState {
                case .walletAdded(let wallet):
                    coreAppCoordinator.showHome(accountState: .walletAdded(wallet))
                case .webAccountWithParkedDomains(let user):
                    coreAppCoordinator.showHome(accountState: .webAccount(user))
                default:
                    Void()
                }
            }
            completion?()
        case .dataLoadedLate:
            return
        }
    }
    
    func isAppVersionSupported(info: AppVersionInfo) -> Bool {
        guard let currentVersion = try? Version.getCurrent() else {
            Debugger.printFailure("Failed to get app version", critical: true)
            return true
        }
        return currentVersion >= info.minSupportedVersion
    }
    
    @MainActor
    func appVersionUpdated(_ appVersion: AppVersionInfo) {
        if appVersion.dotcoinDeprecationReleased == true {
            Constants.deprecatedTLDs = ["coin"]
        }
        Constants.newNonInteractableTLDs = [Constants.ensDomainTLD]
        if !appVersion.mintingIsEnabled {
            appContext.toastMessageService.showToast(.mintingUnavailable, isSticky: true)
        } else {
            appContext.toastMessageService.removeStickyToast(.mintingUnavailable)
        }
    }
    
    func wakeUpServices(walletConnectServiceV2: WalletConnectServiceV2Protocol) {
        walletConnectServiceV2.setWalletUIHandler(coreAppCoordinator) // wake up
        _ = AppGroupsBridgeFromDataAggregatorService.shared // wake up
    }
    
    func checkFirstLaunchAfterGIFSupportReleased() {
        /// When GIF support released, we need to clear images cache to avoid issue when GIF image was saved as regular image.
        /// Release: End of Jan, 2023
        if UserDefaults.isFirstLaunchAfterGIFSupportReleased {
            Task {
                await appContext.imageLoadingService.clearStoredImages()
                await appContext.imageLoadingService.clearCache()
                UserDefaults.isFirstLaunchAfterGIFSupportReleased = false
            }
        }
    }
    
    /// Placeholders aren't stored on the disk, they're generated after each launch and cached in memory when needed.
    /// Downside: When add coins screen get opened, it require multiple placeholders to be prepared at a time, which cause UI hang.
    /// Solution: Prepare popular placeholders in advance while we show 1 sec of launch screen
    func preparePopularPlaceholders() {
        Task.detached(priority: .background) {
            let toPrepare = Constants.popularCoinsTickers.map({ String($0.first ?? "a") }).joined() + "0ab"
            for char in toPrepare {
                _ = await appContext.imageLoadingService.loadImage(from: .initials(String(char),
                                                                                   size: .default,
                                                                                   style: .gray),
                                                                   downsampleDescription: nil)
            }
        }
    }
}

// MARK: - Private methods
private extension AppLaunchService {
    actor InitialMintingStateMachine {
        enum State {
            case loading
            case maxIntervalPassed(_ mintingState: DomainsCollectionMintingState)
            case dataLoadedInTime(_ mintingState: DomainsCollectionMintingState)
            case dataLoadedLate(_ mintingState: DomainsCollectionMintingState)
        }

        enum Event {
            case didAuthorise
            case didPassMaxWaitingTime(preliminaryMintingState: DomainsCollectionMintingState)
            case didLoadData(mintingState: DomainsCollectionMintingState)
        }
        
        private var didAuthorise: Bool = false
        private var preliminaryMintingState: DomainsCollectionMintingState? = nil
        private var loadedMintingState: DomainsCollectionMintingState? = nil
        private(set) var state: State = .loading
        private(set) var appVersionInfo: AppVersionInfo? = nil

        func stateAfter(event: Event) -> State? {
            switch (state, event) {
            case (.loading, .didAuthorise):
                self.didAuthorise = true
                if let mintingState = loadedMintingState {
                    state = .dataLoadedInTime(mintingState)
                    return state
                } else if let mintingState = preliminaryMintingState {
                    state = .maxIntervalPassed(mintingState)
                    return state
                }
            case (.loading, .didPassMaxWaitingTime(let preliminaryMintingState)):
                self.preliminaryMintingState = preliminaryMintingState
                if didAuthorise {
                    state = .maxIntervalPassed(preliminaryMintingState)
                    return state
                }
            case (.loading, .didLoadData(let initialMintingState)):
                self.loadedMintingState = initialMintingState
                if didAuthorise {
                    state = .dataLoadedInTime(initialMintingState)
                    return state
                }
            case (.maxIntervalPassed, .didLoadData(let loadedMintingState)):
                self.loadedMintingState = loadedMintingState
                state = .dataLoadedLate(loadedMintingState)
                return state
            default:
                return nil
            }
            return nil
        }
        
        func set(appVersionInfo: AppVersionInfo) {
            self.appVersionInfo = appVersionInfo
        }
    }
}
