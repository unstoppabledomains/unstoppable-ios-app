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
    @Published var isSelectWalletPresented: Bool = false
    @Published var isConnectedAppsListPresented: Bool = false
    @Published var tabViewSelection: HomeTab = .wallets
    @Published var pullUp: ViewPullUpConfigurationType?
    @Published var walletViewNavPath: NavigationPath = NavigationPath()
    @Published var presentedNFT: NFTDisplayInfo?
    @Published var presentedDomain: DomainPresentationDetails?
    @Published var presentedPublicDomain: PublicDomainPresentationDetails?
    @Published var presentedUBTSearch: UBTSearchPresentationDetails?
    @Published var resolvingPrimaryDomainWallet: WalletEntity?
    weak var mintingNav: MintDomainsNavigationController?
    weak var chatsListCoordinator: ChatsListCoordinator?
    
    let id: UUID = UUID()
    private var topViews = 0
    private var cancellables: Set<AnyCancellable> = []
    
    init(profile: UserProfile) {
        self.profile = profile
        NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification).sink { [weak self] _ in
            self?.didRegisterShakeDevice()
        }.store(in: &cancellables)
        appContext.userProfileService.selectedProfilePublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedProfile in
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
            await showHomeScreenList()
            walletViewNavPath.append(HomeWalletNavigationDestination.purchaseDomains(domainsPurchasedCallback: { _ in }))
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
                           dismissCallback: EmptyCallback?) async {
        await popToRootAndWait()
        tabViewSelection = .wallets
        presentedDomain = .init(domain: domain,
                                wallet: wallet,
                                preRequestedProfileAction: preRequestedAction,
                                dismissCallback: dismissCallback)
    }
    
    func showPublicDomainProfile(of domain: PublicDomainDisplayInfo,
                                 viewingDomain: DomainItem,
                                 preRequestedAction: PreRequestedProfileAction?) {
        presentedPublicDomain = .init(domain: domain,
                                      viewingDomain: viewingDomain,
                                      preRequestedAction: preRequestedAction,
                                      delegate: self)
    }
    
    func showPublicDomainProfileFromDeepLink(of domain: PublicDomainDisplayInfo,
                                             viewingDomain: DomainItem,
                                             preRequestedAction: PreRequestedProfileAction?) async {
        await popToRootAndWait()
        showPublicDomainProfile(of: domain,
                                viewingDomain: viewingDomain,
                                preRequestedAction: preRequestedAction)
    }
    
    func runMintDomainsFlow(with mode: MintDomainsNavigationController.Mode) {
        Task { @MainActor in
            let domains = appContext.walletsDataService.wallets.combinedDomains()
            
            let topPresentedViewController = appContext.coreAppCoordinator.topVC
            if let mintingNav {
                mintingNav.setMode(mode)
            } else if let _ = topPresentedViewController as? AddWalletNavigationController {
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
            
            walletViewNavPath.append(HomeWalletNavigationDestination.qrScanner(selectedWallet: wallet))
        }
    }
    
    func runAddWalletFlow(initialAction: WalletsListViewPresenter.InitialAction = .none) {
        Task {
            await popToRootAndWait()
            tabViewSelection = .wallets
            walletViewNavPath.append(HomeWalletNavigationDestination.walletsList(initialAction))
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
    
    func publicProfileDidSelectMessagingWithProfile(_ profile: PublicDomainDisplayInfo, by userDomain: DomainItem) {
        Task {
            var messagingProfile: MessagingChatUserProfileDisplayInfo
            if let wallet = appContext.walletsDataService.wallets.first(where: { $0.address == userDomain.ownerWallet }),
               let profile = try? await appContext.messagingService.getUserMessagingProfile(for: wallet) {
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
                       return details.otherUser.wallet.lowercased() == profile.walletAddress
                   case .group, .community:
                       return false
                   }
               }) {
                await showChat(chat.id, profile: messagingProfile)
            } else {
                let messagingUserDisplayInfo = MessagingChatUserDisplayInfo(wallet: profile.walletAddress.ethChecksumAddress(),
                                                                            domainName: profile.name)
                await showChatWith(options: .newChat(description: .init(userInfo: messagingUserDisplayInfo, messagingService: Constants.defaultMessagingServiceIdentifier)), profile: messagingProfile)
            }
        }
    }
    
    func publicProfileDidSelectOpenLeaderboard() {
        guard let topVC else { return }
        
        topVC.openLink(.badgesLeaderboard)
    }
    
    func publicProfileDidSelectViewInBrowser(domainName: String) {
        guard let topVC else { return }
        
        topVC.openLink(.domainProfilePage(domainName: domainName))
    }
}

// MARK: - Private methods
private extension HomeTabRouter {
    func popToRoot() {
        isSelectWalletPresented = false
        isConnectedAppsListPresented = false
        presentedNFT = nil
        presentedDomain = nil
        presentedPublicDomain = nil
        resolvingPrimaryDomainWallet = nil
        walletViewNavPath = .init()
        chatsListCoordinator?.popToChatsList()
    }
    
    func popToRootAndWait() async {
        popToRoot()
        await waitForScreenClosed()
    }
    
    func waitForScreenClosed() async {
        await withSafeCheckedMainActorContinuation { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion(Void())
            }
        }
    }
    
    func isMintingAvailable() async -> Bool {
        guard let topPresentedViewController = appContext.coreAppCoordinator.topVC else { return false }

        guard appContext.networkReachabilityService?.isReachable == true else {
            await appContext.pullUpViewService.showYouAreOfflinePullUp(in: topPresentedViewController,
                                                                       unavailableFeature: .minting)
            return false
        }
        
        guard User.instance.getAppVersionInfo().mintingIsEnabled else {
            await appContext.pullUpViewService.showMintingNotAvailablePullUp(in: topPresentedViewController)
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
                            by domain: DomainDisplayInfo) {
        let domain = domain.toDomainItem()
        let publicDomainInfo = PublicDomainDisplayInfo(walletAddress: btDomainInfo.walletAddress,
                                                       name: btDomainInfo.domainName)
        showPublicDomainProfile(of: publicDomainInfo,
                                viewingDomain: domain,
                                preRequestedAction: nil)
    }
}

// MARK: - DomainPresentationDetails
extension HomeTabRouter {
    struct DomainPresentationDetails: Identifiable {
        var id: String { domain.name }
        
        let domain: DomainDisplayInfo
        let wallet: WalletEntity
        var preRequestedProfileAction: PreRequestedProfileAction? = nil
        var dismissCallback: EmptyCallback? = nil
    }
    
    struct PublicDomainPresentationDetails: Identifiable {
        var id: String { domain.name }
        
        let domain: PublicDomainDisplayInfo
        let viewingDomain: DomainItem
        var preRequestedAction: PreRequestedProfileAction? = nil
        var delegate: PublicProfileViewDelegate
    }
    
    struct UBTSearchPresentationDetails: Identifiable {
        let id = UUID()
        let searchResultCallback: UDBTSearchResultCallback
    }
}
