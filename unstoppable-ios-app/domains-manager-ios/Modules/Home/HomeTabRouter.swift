//
//  HomeTabRouter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.01.2024.
//

import SwiftUI
import Combine

@MainActor
final class HomeTabRouter: ObservableObject {
    @Published var profile: UserProfile
    @Published var isTabBarVisible: Bool = true
    @Published var isSelectProfilePresented: Bool = false
    @Published var isConnectedAppsListPresented: Bool = false
    @Published var showingUpdatedToWalletGreetings: Bool = false
    @Published var tabViewSelection: HomeTab = .wallets
    @Published var pullUp: ViewPullUpConfigurationType?
    @Published var walletViewNavPath: [HomeWalletNavigationDestination] = []
    @Published var chatTabNavPath: [HomeChatNavigationDestination] = []
    @Published var exploreTabNavPath: [HomeExploreNavigationDestination] = []
    @Published var activityTabNavPath: [HomeActivityNavigationDestination] = []
    @Published var presentedNFT: NFTDisplayInfo?
    
    @Published var presentedDomain: DomainPresentationDetails?
    @Published var presentedPublicDomain: PublicProfileViewConfiguration?
    @Published var presentedUBTSearch: UBTSearchPresentationDetails?
    @Published var resolvingPrimaryDomainWallet: SelectRRPresentationDetails?
    @Published var showingWalletInfo: WalletEntity?
    @Published var sendCryptoInitialData: SendCryptoAsset.InitialData?
    weak var mintingNav: MintDomainsNavigationController?
    weak var chatsListCoordinator: ChatsListCoordinator?
    weak var homeWalletViewCoordinator: HomeWalletViewCoordinator?
    
    let id: UUID = UUID()
    private var topViews = 0
    private var cancellables: Set<AnyCancellable> = []
    private(set) var isUpdatingPurchasedProfiles = false
    
    init(profile: UserProfile,
         userProfilesService: UserProfilesServiceProtocol = appContext.userProfilesService) {
        self.profile = profile
        NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification).sink { [weak self] _ in
            self?.didRegisterShakeDevice()
        }.store(in: &cancellables)
        userProfilesService.selectedProfilePublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedProfile in
            if let selectedProfile {
                self?.profile = selectedProfile
            }
        }.store(in: &cancellables)
    }
  
}

// MARK: - Open methods
extension HomeTabRouter {
    func dismissPullUpMenu() async {
        if pullUp != nil {
            pullUp = nil
            await waitForScreenClosed()
        }
    }
    
    func showHomeScreenList() async {
        await popToRootAndWait()
        tabViewSelection = .wallets
    }
    
    func runPurchaseFlow() {
        Task {
            let currentTab = tabViewSelection
            await showHomeScreenList()
            await waitBeforeNextNavigationIfTabNot(currentTab)
            
            walletViewNavPath.append(HomeWalletNavigationDestination.purchaseDomains(domainsPurchasedCallback: { [weak self] result in
                switch result {
                case .cancel:
                    return
                case .purchased:
                    self?.homeWalletViewCoordinator?.domainPurchased()
                }
            }))
        }
    }
    
    func runBuyCryptoFlowTo(wallet: WalletEntity) {
        Task {
            await showHomeScreenList()
            guard let topVC else { return }
            
            let link: String.Links
            if let rrDomain = wallet.rrDomain {
                link = .buyCryptoToDomain(rrDomain.name)
            } else {
                link = .buyCryptoToWallet(wallet.address)
            }
            
            topVC.openLinkInSafari(link)
        }
    }
  
    func primaryDomainMinted(_ domain: DomainDisplayInfo) async {
        if let mintingNav {
            mintingNav.refreshMintingProgress()
            Debugger.printWarning("Primary domain minted: Already on minting screen")
            return
        }
    }
    
    func showPullUpLoading() {
        pullUp = .custom(.loadingIndicator())
    }
    
    func jumpToChatsList(profile: MessagingChatUserProfileDisplayInfo?) async {
        await showChatsListWith(options: .showChatsList(profile: profile))
    }
    
    func showChat(_ chatId: String, profile: MessagingChatUserProfileDisplayInfo) async {
        await showChatWith(options: .existingChat(chatId: chatId), profile: profile)
    }
    
    func showChatWith(options: ChatsList.PresentOptions.PresentChatOptions, profile: MessagingChatUserProfileDisplayInfo) async {
        await showChatsListWith(options: .showChat(options: options, profile: profile))
    }
    
    func showChannel(_ channelId: String, profile: MessagingChatUserProfileDisplayInfo) async {
        await showChatsListWith(options: .showChannel(channelId: channelId, profile: profile))
    }
    
    func showDomainProfile(_ domain: DomainDisplayInfo,
                           wallet: WalletEntity,
                           preRequestedAction: PreRequestedProfileAction?,
                           shouldResetNavigation: Bool = true,
                           sourceScreen: DomainProfileViewPresenter.SourceScreen = .domainsCollection) async {
        if shouldResetNavigation {
            await popToRootAndWait()
            tabViewSelection = .wallets
        }
        await askToFinishSetupPurchasedProfileIfNeeded(domains: wallet.domains)
        guard let topVC else { return }

        
        switch domain.usageType {
        case .newNonInteractable:
            guard let walletAddress = domain.ownerWallet else {
                Debugger.printInfo("No profile for a non-interactible domain")
                return
            }
            let domain = domain.toDomainItem()
            let domainPublicInfo = PublicDomainDisplayInfo(walletAddress: walletAddress, name: domain.name)
            showPublicDomainProfile(of: domainPublicInfo, by: wallet, preRequestedAction: nil)
        case .deprecated(let tld):
            do {
                try await appContext.pullUpViewService.showDomainTLDDeprecatedPullUp(tld: tld, in: topVC)
                await topVC.dismissPullUpMenu()
                topVC.openLink(.deprecatedCoinTLDPage)
            } catch { }
        case .normal:
            guard !domain.isMinting else {
                showDomainMintingInProgress(domain)
                return }
            guard !domain.isTransferring else {
                showDomainTransferringInProgress(domain)
                return }
            
            presentedDomain = .init(domain: domain,
                                    wallet: wallet,
                                    preRequestedProfileAction: preRequestedAction,
                                    sourceScreen: sourceScreen)
        case .parked:
            let action = await UDRouter().showDomainProfileParkedActionModule(in: topVC,
                                                                              domain: domain,
                                                                              imagesInfo: .init())
            switch action {
            case .claim:
                runMintDomainsFlow(with: .default(email: appContext.firebaseParkedDomainsAuthenticationService.firebaseUser?.email))
            case .close:
                return
            }
        }
    }
    
    func showPublicDomainProfile(of domain: PublicDomainDisplayInfo,
                                 by wallet: WalletEntity? = nil,
                                 preRequestedAction: PreRequestedProfileAction? = nil) {
        presentedPublicDomain = .init(domain: domain,
                                      viewingWallet: wallet,
                                      preRequestedAction: preRequestedAction,
                                      delegate: self)
    }
    
    func showPublicDomainProfileFromDeepLink(of domain: PublicDomainDisplayInfo,
                                             by wallet: WalletEntity,
                                             preRequestedAction: PreRequestedProfileAction?) async {
        await popToRootAndWait()
        showPublicDomainProfile(of: domain,
                                by: wallet,
                                preRequestedAction: preRequestedAction)
    }
    
    func runMintDomainsFlow(with mode: MintDomainsNavigationController.Mode) {
        Task { @MainActor in
            let domains = appContext.walletsDataService.wallets.combinedDomains()
            
            if let mintingNav {
                mintingNav.setMode(mode)
            } else if let _ = topVC as? AddWalletNavigationController {
                // MARK: - Ignore minting request when add/import/connect wallet
            } else if resolvingPrimaryDomainWallet == nil {
                await popToRootAndWait()
                guard await isMintingAvailable() else { return }
                
                let mintedDomains = domains.interactableItems()
                
                walletViewNavPath.append(HomeWalletNavigationDestination.minting(mode: mode,
                                                                                 mintedDomains: mintedDomains,
                                                                                 domainsMintedCallback: { result in
                }, mintingNavProvider: { [weak self] mintingNav in
                    self?.mintingNav = mintingNav
                }))
            }
        }
    }
    
    func didRegisterShakeDevice() {
        Task {
            await popToRootAndWait()
            presentedUBTSearch = .init(searchResultCallback: { [weak self] device, domain in
                self?.didSelectUBTDomain(device, by: domain)
            })
        }
    }
    
    func showQRScanner() {
        Task {
            await popToRootAndWait()
            guard let wallet = appContext.walletsDataService.selectedWallet else { return }
            
            tabViewSelection = .wallets
            walletViewNavPath.append(HomeWalletNavigationDestination.qrScanner(selectedWallet: wallet))
        }
    }
    
    func runAddWalletFlow(initialAction: SettingsView.InitialAction = .none) {
        Task {
            await popToRootAndWait()
            tabViewSelection = .wallets
            walletViewNavPath.append(HomeWalletNavigationDestination.settings(initialAction))
        }
    }
    
    func askToFinishSetupPurchasedProfileIfNeeded(domains: [DomainDisplayInfo]) async {
        let profilesReadyToSubmit = getPurchasedProfilesReadyToSubmit(domains: domains)
        if !profilesReadyToSubmit.isEmpty,
           !isUpdatingPurchasedProfiles {
            isUpdatingPurchasedProfiles = true
            let requests = profilesReadyToSubmit.compactMap { profile -> UpdateProfilePendingChangesRequest? in
                if let domain = domains.first(where: { $0.name == profile.domainName }) {
                    return UpdateProfilePendingChangesRequest(pendingChanges: profile, domain: domain.toDomainItem())
                }
                Debugger.printFailure("Failed to find domain item for pending profile update", critical: true)
                return nil
            }
            await withSafeCheckedMainActorContinuation { completion in
                pullUp = .default(.showFinishSetupProfilePullUp(pendingProfile: profilesReadyToSubmit[0],
                                                                signCallback: {
                    completion(Void())
                }))
            }
            await finishSetupPurchasedProfileIfNeeded(domains: domains, requests: requests)
        }
    }
    
    func isChatOpenedWith(chatId: String) -> Bool {
        chatTabNavPath.first(where: { screen in
            if case .chat(_, let conversationState) = screen,
               case .existingChat(let chat) = conversationState {
                return chat.id.lowercased().contains(chatId.lowercased())
            }
            return false
        }) != nil
    }
    
    func isChannelOpenedWith(channelId: String) -> Bool {
        chatTabNavPath.first(where: { screen in
            if case .channel(_, let channel) = screen {
                return channel.channel.normalized.contains(channelId.normalized)
            }
            return false
        }) != nil
    }
    
    func popToRoot() {
        isSelectProfilePresented = false
        isConnectedAppsListPresented = false
        showingUpdatedToWalletGreetings = false
        presentedNFT = nil
        presentedDomain = nil
        presentedPublicDomain = nil
        resolvingPrimaryDomainWallet = nil
        showingWalletInfo = nil
        sendCryptoInitialData = nil
        walletViewNavPath.removeAll()
        chatTabNavPath.removeAll()
        exploreTabNavPath.removeAll()
    }
    
    func startMessagingWith(walletAddress: HexAddress,
                            domainName: DomainName?,
                            by wallet: WalletEntity) {
        Task {
            var messagingProfile: MessagingChatUserProfileDisplayInfo
            if let profile = try? await appContext.messagingService.getUserMessagingProfile(for: wallet) {
                messagingProfile = profile
            } else if let profile = await appContext.messagingService.getLastUsedMessagingProfile(among: nil) {
                messagingProfile = profile
            } else {
                await jumpToChatsList(profile: nil)
                return
            }
            
            if let chatsList = try? await appContext.messagingService.getChatsListForProfile(messagingProfile),
               let chat = chatsList.first(where: { chat in
                   switch chat.type {
                   case .private(let details):
                       return details.otherUser.wallet.lowercased() == walletAddress
                   case .group, .community:
                       return false
                   }
               }) {
                await showChat(chat.id, profile: messagingProfile)
            } else {
                let messagingUserDisplayInfo = MessagingChatUserDisplayInfo(wallet: walletAddress.ethChecksumAddress(),
                                                                            domainName: domainName)
                await showChatWith(options: .newChat(description: .init(userInfo: messagingUserDisplayInfo, messagingService: Constants.defaultMessagingServiceIdentifier)), profile: messagingProfile)
            }
        }
    }
}

// MARK: - Pull up related
extension HomeTabRouter {
    func currentPullUp(id: UUID) -> Binding<ViewPullUpConfigurationType?> {
        if topViews != 0 {
            guard self.id != id else {
                return Binding { nil } set: { newValue in }
            }
        } else {
            guard self.id == id else {
                return Binding { nil } set: { newValue in }
            }
        }
        return Binding { [weak self] in
            self?.pullUp
        } set: { [weak self] newValue in
            self?.pullUp = newValue
        }
    }
    
    func registerTopView(id: UUID) {
        topViews += 1
    }
    
    func unregisterTopView(id: UUID) {
        topViews -= 1
        topViews = max(0, topViews)
    }
}

// MARK: - Open methods
extension HomeTabRouter: PublicProfileViewDelegate {
    private var topVC: UIViewController? { appContext.coreAppCoordinator.topVC }
    
    func publicProfileDidSelectBadge(_ badge: DomainProfileBadgeDisplayInfo, in profile: DomainName) {
        guard let topVC else { return }
        appContext.pullUpViewService.showBadgeInfoPullUp(in: topVC,
                                                         badgeDisplayInfo: badge,
                                                         domainName: profile)
    }
    
    func publicProfileDidSelectShareProfile(_ profile: DomainName) {
        guard let topVC else { return }

        topVC.shareDomainProfile(domainName: profile, isUserDomain: false)
    }
    
    func publicProfileDidSelectMessagingWithProfile(_ profile: PublicDomainDisplayInfo, by wallet: WalletEntity) {
        startMessagingWith(walletAddress: profile.walletAddress, domainName: profile.name, by: wallet)
    }
    
    func publicProfileDidSelectOpenLeaderboard() {
        guard let topVC else { return }
        
        topVC.openLink(.badgesLeaderboard)
    }
    
    func publicProfileDidSelectViewInBrowser(domainName: String) {
        guard let topVC else { return }
        
        topVC.openLink(.domainProfilePage(domainName: domainName))
    }
    
    func showDomainMintingInProgress(_ domain: DomainDisplayInfo) {
        guard domain.isMinting,
              let topVC else { return }
        
        let mintingDomainWithDisplayInfo = MintingDomainWithDisplayInfo(displayInfo: domain)
        UDRouter().showMintingDomainsInProgressScreen(mintingDomainsWithDisplayInfo: [mintingDomainWithDisplayInfo],
                                                      mintingDomainSelectedCallback: { _ in },
                                                      in: topVC)
    }
    
    func showDomainTransferringInProgress(_ domain: DomainDisplayInfo) {
        guard let topVC else { return }
        
        UDRouter().showTransferInProgressScreen(domain: domain, in: topVC)
    }
    
}

// MARK: - Private methods
private extension HomeTabRouter {
    func popToRootAndWait() async {
        popToRoot()
        await waitForScreenClosed()
    }
    
    func waitForScreenClosed() async {
        await withSafeCheckedMainActorContinuation { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                completion(Void())
            }
        }
    }
    
    func isMintingAvailable() async -> Bool {
        guard let topVC else { return false }

        guard appContext.networkReachabilityService?.isReachable == true else {
            await appContext.pullUpViewService.showYouAreOfflinePullUp(in: topVC,
                                                                       unavailableFeature: .minting)
            return false
        }
        
        guard User.instance.getAppVersionInfo().mintingIsEnabled else {
            await appContext.pullUpViewService.showMintingNotAvailablePullUp(in: topVC)
            return false
        }
        
        return true
    }
    
    func showChatsListWith(options: ChatsList.PresentOptions) async {
        tabViewSelection = .messaging
        await popToRootAndWait()
        chatsListCoordinator?.update(presentOptions: options)
    }
    
    func didSelectUBTDomain(_ btDomainInfo: BTDomainUIInfo,
                            by wallet: WalletEntity) {
        let publicDomainInfo = PublicDomainDisplayInfo(walletAddress: btDomainInfo.walletAddress,
                                                       name: btDomainInfo.domainName)
        showPublicDomainProfile(of: publicDomainInfo,
                                by: wallet,
                                preRequestedAction: nil)
    }
    
    func getPurchasedProfilesReadyToSubmit(domains: [DomainDisplayInfo]) -> [DomainProfilePendingChanges] {
        let pendingProfiles = PurchasedDomainsStorage.retrievePendingProfiles()
        return pendingProfiles.filter { profile in
            if let domain = domains.first(where: { $0.name == profile.domainName }),
               domain.state == .default {
                return true
            }
            return false
        }
    }
    
    func finishSetupPurchasedProfileIfNeeded(domains: [DomainDisplayInfo],
                                             requests: [UpdateProfilePendingChangesRequest]) async {
        let pendingProfiles = PurchasedDomainsStorage.retrievePendingProfiles()
        let pendingProfilesLeft = pendingProfiles.filter { profile in
            requests.first(where: { $0.pendingChanges.domainName == profile.domainName }) == nil
        }
        
        do {
            try await NetworkService().updatePendingDomainProfiles(with: requests)
            PurchasedDomainsStorage.setPendingNonEmptyProfiles(pendingProfilesLeft)
            await Task.sleep(seconds: 0.3)
            try? await appContext.walletsDataService.refreshDataForWalletDomain(domains[0].name)
        } catch {
            do {
                try await withSafeCheckedThrowingMainActorContinuation { completion in
                    pullUp = .default(.showFinishSetupProfileFailedPullUp(completion: { result in
                        switch result {
                        case .success:
                            completion(.success(Void()))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }))
                }
                await finishSetupPurchasedProfileIfNeeded(domains: domains, requests: requests)
            } catch {
                PurchasedDomainsStorage.setPendingNonEmptyProfiles(pendingProfilesLeft)
            }
        }
        isUpdatingPurchasedProfiles = false
    }
    
    func waitBeforeNextNavigationIfTabNot(_ tab: HomeTab) async {
        let shouldWaitBeforePush = tabViewSelection != tab
        if shouldWaitBeforePush {
            await Task.sleep(seconds: 0.2)
        }
    }
}

// MARK: - DomainPresentationDetails
extension HomeTabRouter {
    struct DomainPresentationDetails: Identifiable {
        var id: String { domain.name }
        
        let domain: DomainDisplayInfo
        let wallet: WalletEntity
        var preRequestedProfileAction: PreRequestedProfileAction? = nil
        var sourceScreen: DomainProfileViewPresenter.SourceScreen = .domainsCollection
    }
    
    struct UBTSearchPresentationDetails: Identifiable {
        let id = UUID()
        let searchResultCallback: UDBTSearchResultCallback
    }
    
    struct SelectRRPresentationDetails: Identifiable {
        var id: String { wallet.id }
        
        let wallet: WalletEntity
        let mode: ReverseResolutionSelectionView.Mode
        var domainSetCallback: (@MainActor (DomainDisplayInfo)->())? = nil
    }
}
