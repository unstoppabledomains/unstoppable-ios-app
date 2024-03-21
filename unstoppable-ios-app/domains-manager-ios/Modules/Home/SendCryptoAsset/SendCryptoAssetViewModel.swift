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
        case .globalProfileSelected:
            navPath.append(.selectAssetToSend)   
        case .globalWalletAddressSelected:
            navPath.append(.selectAssetToSend)
            
        case .userTokenSelected(let token):
            navPath.append(.selectTokenAmountToSend(token))
        case .userTokenValueSelected(let token):
            navPath.append(.confirmSendToken(token))
            
        case .userDomainSelected(let domain):
            return
        }
    }
    
}
