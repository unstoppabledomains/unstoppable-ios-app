//
//  CoreAppCoordinatorProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.06.2022.
//

import UIKit

@MainActor
protocol CoreAppCoordinatorProtocol: WalletConnectClientUIHandler, ExternalEventsUIHandler {
    var topVC: UIViewController? { get }
    
    func startWith(window: UIWindow)
    func showOnboarding(_ flow: OnboardingNavigationController.OnboardingFlow)
    func showHome(profile: UserProfile)
    func showAppUpdateRequired()
    func setKeyWindow()
    @discardableResult
    func goBackToPreviousApp() -> Bool
    func didRegisterShakeDevice()
    
    func isActiveState(_ state: AppCoordinationState) -> Bool
}

enum AppCoordinationState {
    case chatOpened(chatId: String)
    case channelOpened(channelId: String)
}
