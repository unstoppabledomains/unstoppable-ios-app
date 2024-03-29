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
    private let cryptoSender: CryptoSenderProtocol
    
    init(initialData: SendCryptoAsset.InitialData) {
        self.sourceWallet = initialData.sourceWallet
        self.cryptoSender = CryptoSender.init(wallet: initialData.sourceWallet.udWallet)
    }
    
    func handleAction(_ action: SendCryptoAsset.FlowAction) {
        switch action {
        case .scanQRSelected:
            navPath.append(.scanWalletAddress)
        case .userWalletSelected(let walletEntity):
            navPath.append(.selectAssetToSend(.init(wallet: walletEntity)))
        case .followingDomainSelected(let domainProfile):
            navPath.append(.selectAssetToSend(.init(followingDomain: domainProfile)))
        case .globalProfileSelected(let profile):
            guard let receiver = SendCryptoAsset.AssetReceiver(globalProfile: profile) else { return }
            navPath.append(.selectAssetToSend(receiver))
        case .globalWalletAddressSelected(let address):
            navPath.append(.selectAssetToSend(.init(walletAddress: address)))
            
        case .userTokenToSendSelected(let data):
            navPath.append(.selectTokenAmountToSend(data))
        case .userTokenValueSelected(let data):
            navPath.append(.confirmSendToken(data))
            
        case .userDomainSelected(let data):
            navPath.append(.confirmTransferDomain(data))
        case.didTransferDomain(let domain):
            navPath.append(.domainTransferSuccess(domain))
        }
    }
    
    func canSendToken(_ token: BalanceTokenUIDescription) -> Bool {
        guard let supportedToken = supportedTokenFrom(token: token),
              let chainType = token.blockchainType() else { return false }
        
        
        return cryptoSender.canSendCrypto(token: supportedToken, chainType: chainType)
    }
        
    func supportedTokenFrom(token: BalanceTokenUIDescription) -> CryptoSender.SupportedToken? {
        CryptoSender.SupportedToken(rawValue: token.symbol.uppercased())
    }
}
