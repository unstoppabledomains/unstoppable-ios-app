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
    private let coreAppCoordinator: CoreAppCoordinatorProtocol
    private let udWalletsService: UDWalletsServiceProtocol
    private let userProfilesService: UserProfilesServiceProtocol
    private let udFeatureFlagsService: UDFeatureFlagsServiceProtocol
    private var sceneDelegate: SceneDelegateProtocol?
    private var completion: EmptyAsyncCallback?
    private var listeners: [AppLaunchListenerHolder] = []
    private var isInFullMaintenanceMode = false

    init(coreAppCoordinator: CoreAppCoordinatorProtocol,
         udWalletsService: UDWalletsServiceProtocol,
         userProfilesService: UserProfilesServiceProtocol,
         udFeatureFlagsService: UDFeatureFlagsServiceProtocol) {
        self.coreAppCoordinator = coreAppCoordinator
        self.udWalletsService = udWalletsService
        self.userProfilesService = userProfilesService
        self.udFeatureFlagsService = udFeatureFlagsService
        udFeatureFlagsService.addListener(self)
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
        
        let _ = try? CryptoSender.SupportedToken.getContractArray() // initiate fetching
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

// MARK: - UDFeatureFlagsListener
extension AppLaunchService: UDFeatureFlagsListener {
    func didUpdatedUDFeatureFlag(_ flag: UDFeatureFlag, withValue newValue: Bool) {
        if case .isMaintenanceFullEnabled = flag {
            updateFullMaintenanceState()
        }
    }
    
    private func getFullMaintenanceModeData() -> MaintenanceModeData? {
        let fullMaintenanceModeData: MaintenanceModeData? = udFeatureFlagsService.entityValueFor(flag: .isMaintenanceFullEnabled)
        return fullMaintenanceModeData
    }
    
    private func updateFullMaintenanceState() {
        let fullMaintenanceModeData = getFullMaintenanceModeData()
        if let fullMaintenanceModeData,
           fullMaintenanceModeData.isCurrentlyEnabled != self.isInFullMaintenanceMode {
            self.isInFullMaintenanceMode = fullMaintenanceModeData.isCurrentlyEnabled
            resolveInitialViewController()
        }
        fullMaintenanceModeData?.onMaintenanceStatusUpdate { [weak self] in
            self?.updateFullMaintenanceState()
        }
    }
}

// MARK: - Private methods
private extension AppLaunchService {
    func resolveInitialViewController() {
        let startTime = Date()
        
        Task {
            updateFullMaintenanceState()
            guard !isInFullMaintenanceMode else {
                let maintenanceData: MaintenanceModeData = getFullMaintenanceModeData() ?? .init(isOn: true)
                await coreAppCoordinator.showFullMaintenanceModeOn(maintenanceData: maintenanceData)
                return
            }
            
            do {
                try await initialWalletsCheck()
                
                let appVersion = User.instance.getAppVersionInfo()
                await appVersionUpdated(appVersion)
                
                let onboardingDone = User.instance.getSettings().onboardingDone ?? false
                if let profile = userProfilesService.selectedProfile,
                   onboardingDone {
                    resolveInitialMintingState(startTime: startTime,
                                               profile: profile)
                } else {
                    let wallets = udWalletsService.getUserWallets()
                    let onboardingFlow: OnboardingNavigationController.OnboardingFlow
                    
                    if wallets.isEmpty {
                        onboardingFlow = .newUser(subFlow: nil)
                    } else {
                        onboardingFlow = .existingUser(wallets: wallets)
                    }
                    
                    await coreAppCoordinator.showOnboarding(onboardingFlow)
                    Task.detached(priority: .background) { [unowned self] in
                        try? await sceneDelegate?.authorizeUserOnAppOpening()
                    }
                    completion?()
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
                                    profile: UserProfile) {
        Task {
            await stateMachine.reset()
            
            Task.detached(priority: .medium) { [weak self] in
                guard let self else { return }
                
                let appVersion = await appContext.userDataService.getLatestAppVersion()
                appContext.coinRecordsService.refreshCurrencies(version: appVersion.mobileUnsReleaseVersion ?? Constants.defaultUNSReleaseVersion)
                await self.appVersionUpdated(appVersion)
                await self.stateMachine.set(appVersionInfo: appVersion)
                
                let state = await self.stateMachine.state
                
                switch state {
                case .dataLoadedLate, .dataLoadedInTime, .maxIntervalPassed:
                    self.listeners.forEach { holder in
                        holder.listener?.appLaunchServiceDidUpdateAppVersion()
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
                                              profile: profile)
            }
            
            Task {
                await handleInitialState(await stateMachine.stateAfter(event: .didLoadData),
                                         profile: profile)
            }
            
            Task {
                let timePassed = Date().timeIntervalSince(startTime)
                let timeLeft: TimeInterval = max(0, maximumWaitingTime - timePassed)
                await Task.sleep(seconds: timeLeft)
                
                await handleInitialState(await stateMachine.stateAfter(event: .didPassMaxWaitingTime),
                                         profile: profile)
            }
        }
    }
    
    @MainActor
    func handleInitialState(_ state: InitialMintingStateMachine.State?,
                            profile: UserProfile) async {
        guard let state = state else { return }
        
        switch state {
        case .loading:
            return
        case .maxIntervalPassed, .dataLoadedInTime:
            if isInFullMaintenanceMode {
                coreAppCoordinator.showAppUpdateRequired()
            } else if let newAppVersionInfo = await stateMachine.appVersionInfo,
                      !isAppVersionSupported(info: newAppVersionInfo) {
                coreAppCoordinator.showAppUpdateRequired()
            } else {
                coreAppCoordinator.showHome(profile: profile)
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
        _ = AppGroupsDomainsPFPBridgeService.shared // wake up
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
            case maxIntervalPassed
            case dataLoadedInTime
            case dataLoadedLate
        }

        enum Event {
            case didAuthorise
            case didPassMaxWaitingTime
            case didLoadData
        }
        
        private var didAuthorise: Bool = false
        private var didLoadData: Bool = false
        private var didPassMaxWaitingTime: Bool = false
        private(set) var state: State = .loading
        private(set) var appVersionInfo: AppVersionInfo? = nil

        func stateAfter(event: Event) -> State? {
            switch (state, event) {
            case (.loading, .didAuthorise):
                self.didAuthorise = true
                if didLoadData {
                    state = .dataLoadedInTime
                    return state
                } else if didPassMaxWaitingTime {
                    state = .maxIntervalPassed
                    return state
                }
            case (.loading, .didPassMaxWaitingTime):
                self.didPassMaxWaitingTime = true
                if didAuthorise {
                    state = .maxIntervalPassed
                    return state
                }
            case (.loading, .didLoadData):
                self.didLoadData = true
                if didAuthorise {
                    state = .dataLoadedInTime
                    return state
                }
            case (.maxIntervalPassed, .didLoadData):
                state = .dataLoadedLate
                return state
            default:
                return nil
            }
            return nil
        }
        
        func set(appVersionInfo: AppVersionInfo) {
            self.appVersionInfo = appVersionInfo
        }
        
        func reset() {
            didAuthorise = false
            didLoadData = false
            didPassMaxWaitingTime = false
            state = .loading
            appVersionInfo = nil
        }
    }
}
