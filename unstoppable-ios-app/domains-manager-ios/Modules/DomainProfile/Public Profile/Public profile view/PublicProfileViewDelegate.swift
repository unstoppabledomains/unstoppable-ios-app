//
//  PublicProfileViewDelegate.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.08.2023.
//

import UIKit

protocol PublicProfileViewDelegate: AnyObject {
    func publicProfileDidSelectBadge(_ badge: DomainProfileBadgeDisplayInfo, in profile: DomainName)
    func publicProfileDidSelectShareProfile(_ profile: DomainName)
    func publicProfileDidSelectMessagingWithProfile(_ profile: PublicDomainDisplayInfo, by userDomain: DomainItem)
    func publicProfileDidSelectOpenLeaderboard()
}

// MARK: - Open methods
extension UIViewController: PublicProfileViewDelegate {
    func publicProfileDidSelectBadge(_ badge: DomainProfileBadgeDisplayInfo, in profile: DomainName) {
        appContext.pullUpViewService.showBadgeInfoPullUp(in: getViewControllerToPresent(),
                                                         badgeDisplayInfo: badge,
                                                         domainName: profile)
    }
    
    func publicProfileDidSelectShareProfile(_ profile: DomainName) {
        getViewControllerToPresent().shareDomainProfile(domainName: profile, isUserDomain: false)
    }
    
    func publicProfileDidSelectMessagingWithProfile(_ profile: PublicDomainDisplayInfo, by userDomain: DomainItem) {
        Task {
            let displayInfo = DomainDisplayInfo(domainItem: userDomain, isSetForRR: false)
            var messagingProfile: MessagingChatUserProfileDisplayInfo
            if let profile = try? await appContext.messagingService.getUserProfile(for: displayInfo) {
                messagingProfile = profile
            } else if let profile = await appContext.messagingService.getLastUsedMessagingProfile(among: nil) {
                messagingProfile = profile
            } else {
                try? await appContext.coreAppCoordinator.handle(uiFlow: .showChatsList(profile: nil))
                return
            }
            
            let uiFlowToRun: ExternalEventUIFlow
            if let chatsList = try? await appContext.messagingService.getChatsListForProfile(messagingProfile),
               let chat = chatsList.first(where: { chat in
                   switch chat.type {
                   case .private(let details):
                       return details.otherUser.wallet.lowercased() == profile.walletAddress
                   case .group:
                       return false
                   }
               }) {
                uiFlowToRun = .showChat(chatId: chat.id, profile: messagingProfile)
            } else {
                let messagingUserDisplayInfo = MessagingChatUserDisplayInfo(wallet: profile.walletAddress.ethChecksumAddress(),
                                                                            domainName: profile.name)
                uiFlowToRun = .showNewChat(userInfo: messagingUserDisplayInfo, profile: messagingProfile)
            }
            
            try? await appContext.coreAppCoordinator.handle(uiFlow: uiFlowToRun)
        }
    }
    
    func publicProfileDidSelectOpenLeaderboard() {
        getViewControllerToPresent().openLink(.badgesLeaderboard)
    }
    
    private func getViewControllerToPresent() -> UIViewController {
        topVisibleViewController()
    }
}
