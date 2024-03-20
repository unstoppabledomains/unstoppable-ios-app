//
//  SendCryptoAssetViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import Foundation

final class SendCryptoAssetViewModel: ObservableObject {
        
    @Published var sourceWallet: WalletEntity
    @Published var navigationState: NavigationStateManager?
    
    @Published var navPath: [SendCryptoAsset.NavigationDestination] = []
    
    init(initialData: SendCryptoAsset.InitialData) {
        self.sourceWallet = initialData.sourceWallet
    }
    
    func handleAction(_ action: SendCryptoAsset.FlowAction) {
        switch action {
        case .scanQRSelected:
            navPath.append(.selectAssetToSend)
        case .userWalletSelected(let walletEntity):
            navPath.append(.selectAssetToSend)
        case .followingDomainSelected(let domainName):
            navPath.append(.selectAssetToSend)
        case .userTokenSelected(let token):
            return
        case .userDomainSelected(let domain):
            return
        }
    }
    
}
