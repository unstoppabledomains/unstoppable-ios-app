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
            // Common path
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
            
            // Send crypto
        case .userTokenToSendSelected(let data):
            navPath.append(.selectTokenAmountToSend(data))
        case .userTokenValueSelected(let data):
            navPath.append(.confirmSendToken(data))
        case .didSendCrypto(let data, let txHash):
            navPath.append(.cryptoSendSuccess(data: data, txHash: txHash))
            
            // Transfer domain
        case .userDomainSelected(let data):
            navPath.append(.confirmTransferDomain(data))
        case.didTransferDomain(let domain):
            navPath.append(.domainTransferSuccess(domain))
        }
    }
    
    func canSendToken(_ token: BalanceTokenUIDescription) -> Bool {
        guard let supportedToken = try? getSupportedTokenFor(balanceToken: token),
              let chainType = token.blockchainType else { return false }
        
        return cryptoSender.canSendCrypto(token: supportedToken, chainType: chainType)
    }
    
    func sendCryptoTokenWith(sendData: SendCryptoAsset.SendTokenAssetData,
                             txSpeed: SendCryptoAsset.TransactionSpeed) async throws -> String {
        let crypto: CryptoSendingSpec
        
        if sendData.isSendingAllTokens() {
            crypto = try await getMaxTokenAmountToSendConsideringGasFee(sendData: sendData, txSpeed: txSpeed)
        } else {
            crypto = try getCryptoSendingSpecFor(sendData: sendData, txSpeed: txSpeed)
        }
        
        let chain = try getChainSpecFor(balanceToken: sendData.token)
        let toAddress = sendData.receiverAddress
        
        return try await cryptoSender.sendCrypto(crypto: crypto, chain: chain, toAddress: toAddress)
    }
    
    private func getMaxTokenAmountToSendConsideringGasFee(sendData: SendCryptoAsset.SendTokenAssetData,
                                                          txSpeed: SendCryptoAsset.TransactionSpeed) async throws -> CryptoSendingSpec {
        let gasPrice = try await computeGasFeeFor(sendData: sendData, txSpeed: txSpeed)
        let tokenAmountToSend = sendData.getTokenAmountValue() - gasPrice
        guard tokenAmountToSend > 0 else {
            throw CryptoSender.Error.insufficientFunds
        }
        
        let token = sendData.token
        
        return try getCryptoSendingSpecFor(token: token,
                                           tokenAmount: tokenAmountToSend,
                                           txSpeed: txSpeed)
    }
    
    func computeGasFeeFor(sendData: SendCryptoAsset.SendTokenAssetData,
                          txSpeed: SendCryptoAsset.TransactionSpeed) async throws -> Double {
        let crypto = try getCryptoSendingSpecFor(sendData: sendData, txSpeed: txSpeed)
        let chain = try getChainSpecFor(balanceToken: sendData.token)
        let toAddress = sendData.receiverAddress
        
        return try await cryptoSender.computeGasFeeFrom(maxCrypto: crypto, on: chain, toAddress: toAddress).units
    }
    
    func getGasPrices(sendData: SendCryptoAsset.SendTokenAssetData) async throws -> EstimatedGasPrices {
        let chain = try getChainSpecFor(balanceToken: sendData.token)
        
        return try await cryptoSender.fetchGasPrices(on: chain)
    }
    
    private func getCryptoSendingSpecFor(sendData: SendCryptoAsset.SendTokenAssetData,
                                         txSpeed: SendCryptoAsset.TransactionSpeed) throws -> CryptoSendingSpec {
        let token = sendData.token
        let tokenAmount = sendData.getTokenAmountValue()
        
        return try getCryptoSendingSpecFor(token: token,
                                           tokenAmount: tokenAmount,
                                           txSpeed: txSpeed)
    }
    
    private func getCryptoSendingSpecFor(token: BalanceTokenUIDescription,
                                         tokenAmount: Double,
                                         txSpeed: SendCryptoAsset.TransactionSpeed) throws -> CryptoSendingSpec {
        let token = try getSupportedTokenFor(balanceToken: token)
        let amount = EVMTokenAmount(units: tokenAmount)
        let speed = getSpecTransactionSpeedFor(txSpeed: txSpeed)
        
        return CryptoSendingSpec(token: token,
                                 amount: amount,
                                 speed: speed)
    }
    
    private func getChainSpecFor(balanceToken: BalanceTokenUIDescription) throws -> ChainSpec {
        guard let blockchainType = balanceToken.blockchainType else {
            throw CryptoSender.Error.sendingNotSupported
        }
        let env = getCurrentEnvironment()
        
        return ChainSpec(blockchainType: blockchainType,
                         env: env)
    }
    
    private func getCurrentEnvironment() -> UnsConfigManager.BlockchainEnvironment {
        User.instance.getSettings().isTestnetUsed ? .testnet : .mainnet
    }
    
    private func getSupportedTokenFor(balanceToken: BalanceTokenUIDescription) throws -> CryptoSender.SupportedToken {
        guard let token = CryptoSender.SupportedToken(rawValue: balanceToken.symbol.uppercased()) else {
            throw CryptoSender.Error.sendingNotSupported
        }
        return token
    }
    
    private func getSpecTransactionSpeedFor(txSpeed: SendCryptoAsset.TransactionSpeed) -> CryptoSendingSpec.TxSpeed {
        switch txSpeed {
        case .normal:
            return .normal
        case .fast:
            return .fast
        case .urgent:
            return .urgent
        }
    }
    
}
