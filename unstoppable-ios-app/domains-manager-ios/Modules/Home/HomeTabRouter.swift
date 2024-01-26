//
//  HomeTabRouter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.01.2024.
//

import SwiftUI

@MainActor
final class HomeTabRouter: ObservableObject {
    @Published var isTabBarVisible: Bool = true
    @Published var tabViewSelection: HomeTab = .wallets
    @Published var pullUp: ViewPullUpConfigurationType?
    @Published var walletViewNavPath: NavigationPath = NavigationPath()
    @Published var presentedNFT: NFTDisplayInfo?
    @Published var presentedDomain: DomainPresentationDetails?
    @Published var presentedPublicDomain: PublicDomainPresentationDetails?
    @Published var isResolvingPrimaryDomain: Bool = false
    weak var mintingNav: MintDomainsNavigationController?
    weak var chatsListCoordinator: ChatsListCoordinator?
    
    let id: UUID = UUID()
    private var topViews = 0
  
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
                                      preRequestedAction: preRequestedAction)
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
            let domains = await appContext.dataAggregatorService.getDomainsDisplayInfo()
            
            let topPresentedViewController = appContext.coreAppCoordinator.topVC
            if let mintingNav {
                mintingNav.setMode(mode)
            } else if let _ = topPresentedViewController as? AddWalletNavigationController {
                // MARK: - Ignore minting request when add/import/connect wallet
            } else if !isResolvingPrimaryDomain {
                await popToRootAndWait()
                guard await isMintingAvailable() else { return }
                
                let mintedDomains = domains.interactableItems()
                
                walletViewNavPath.append(HomeWalletView.NavigationDestination.minting(mode: mode, 
                                                                                      mintedDomains: mintedDomains,
                                                                                      domainsMintedCallback: { result in
                }))
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

// MARK: - Private methods
private extension HomeTabRouter {
    func popToRoot() {
        presentedNFT = nil
        presentedDomain = nil
        presentedPublicDomain = nil
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
    }
}
