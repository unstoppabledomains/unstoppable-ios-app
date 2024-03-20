//
//  SendCryptoViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import Foundation

final class SendCryptoViewModel: ObservableObject {
        
    @Published var sourceWallet: WalletEntity
    @Published var navigationState: NavigationStateManager?
    
    @Published var navPath: [SendCryptoNavigationDestination] = []
    
    init(initialData: SendCryptoInitialData) {
        self.sourceWallet = initialData.sourceWallet
    }
    
        
}
