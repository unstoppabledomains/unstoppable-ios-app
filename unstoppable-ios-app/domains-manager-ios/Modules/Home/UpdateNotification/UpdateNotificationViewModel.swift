//
//  UpdateNotificationViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.11.2025.
//

import SwiftUI
import Combine

@MainActor
final class UpdateNotificationViewModel: ObservableObject {
    
    @Published private(set) var hasMPCWallets = false
    @Published private(set) var hasPrivateKeyWallets = false
    
    init() {
        detectWalletTypes()
    }
    
    func didTapGotIt(dontShowAgain: Bool) {
        if dontShowAgain {
            UserDefaults.isV2UpdateNotificationDismissed = true
        }
    }
    
    private func detectWalletTypes() {
        let wallets = appContext.udWalletsService.getUserWallets()
        
        hasMPCWallets = wallets.contains { $0.type == .mpc }
        
        let privateKeyWalletTypes: Set<WalletType> = [.privateKeyEntered, .generatedLocally, .defaultGeneratedLocally, .mnemonicsEntered]
        hasPrivateKeyWallets = wallets.contains { privateKeyWalletTypes.contains($0.type) }
    }
}

