//
//  CoreAppCoordinatorProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.06.2022.
//

import UIKit

@MainActor
protocol CoreAppCoordinatorProtocol: WalletConnectUIHandler, WalletConnectClientUIHandler, ExternalEventsUIHandler {
    func startWith(window: UIWindow)
    func showOnboarding(_ flow: OnboardingNavigationController.OnboardingFlow)
    func showHome(mintingState: DomainsCollectionMintingState)
    func showAppUpdateRequired()
    func setKeyWindow()
    @discardableResult
    func goBackToPreviousApp() -> Bool
}
