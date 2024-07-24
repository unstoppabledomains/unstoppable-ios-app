//
//  PreviewCoreAppCoordinator.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit


final class CoreAppCoordinator: CoreAppCoordinatorProtocol {
    func askToReconnectMPCWallet(_ reconnectData: MPCWalletReconnectData) async {
        
    }
    
    var isReadyToHandleExternalEvents: Bool { true }
    
   
    
    var topVC: UIViewController? { nil }
    
    func startWith(window: UIWindow) {
        
    }
    
    func showOnboarding(_ flow: OnboardingNavigationController.OnboardingFlow) {
        
    }
    
    func showHome(profile: UserProfile) {
        
    }
    
    func showAppUpdateRequired() {
        
    }
    
    func showFullMaintenanceModeOn(maintenanceData: MaintenanceModeData) { }
    
    func setKeyWindow() {
        
    }
    
    func goBackToPreviousApp() -> Bool {
        false
    }
    
    func isActiveState(_ state: AppCoordinationState) -> Bool {
        true
    }
    
    func didDisconnect(walletDisplayInfo: WalletDisplayInfo) {
        
    }
    
    func askToReconnectExternalWallet(_ walletDisplayInfo: WalletDisplayInfo) async -> Bool {
        false
    }
    
    func showExternalWalletDidNotRespondPullUp(for connectingWallet: WCWalletsProvider.WalletRecord) async {
        
    }
    
    func handle(uiFlow: ExternalEventUIFlow) async throws {
        
    }
    
    nonisolated init() {
        
    }
    
    func didRegisterShakeDevice() { }
}
