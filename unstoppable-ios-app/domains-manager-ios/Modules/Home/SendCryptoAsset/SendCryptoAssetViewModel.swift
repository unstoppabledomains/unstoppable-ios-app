//
//  SendCryptoAssetViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import Foundation

@MainActor
final class SendCryptoAssetViewModel: ObservableObject {
        
    @Published var sourceWallet: WalletEntity
    @Published var navigationState: NavigationStateManager?
    @Published var navPath: [SendCryptoAsset.NavigationDestination] = []
    @Published var isLoading = false
    @Published var error: Error?
    private let cryptoSender: UniversalCryptoSenderProtocol
    
    init(initialData: SendCryptoAsset.InitialData) {
        self.sourceWallet = initialData.sourceWallet
        self.cryptoSender = CryptoSender.init(wallet: initialData.sourceWallet.udWallet,
                                              mpcWalletsService: appContext.mpcWalletsService)
    }
    
    func handleAction(_ action: SendCryptoAsset.FlowAction) {
        Task {
            do {
                switch action {
                    // Common path
                case .scanQRSelected:
                    navPath.append(.scanWalletAddress)
                case .userWalletSelected(let walletEntity):
                    let receiver = try await runAsyncThrowingBlock {
                        try await SendCryptoAsset.AssetReceiver(wallet: walletEntity)
                    }
                    navPath.append(.selectAssetToSend(receiver))
                case .followingDomainSelected(let domainProfile):
                    let receiver = try await runAsyncThrowingBlock {
                        try await SendCryptoAsset.AssetReceiver(followingDomain: domainProfile)
                    }
                    navPath.append(.selectAssetToSend(receiver))
                case .globalProfileSelected(let profile):
                    let receiver = try await runAsyncThrowingBlock {
                        try await SendCryptoAsset.AssetReceiver(globalProfile: profile)
                    }
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
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    @discardableResult
    private func runAsyncThrowingBlock<T>(_ block: () async throws -> T) async throws -> T {
        isLoading = true
        let val = try await block()
        isLoading = false
        return val
    }
    
    func canSendToken(_ token: BalanceTokenUIDescription) -> Bool {
        let chainDesc = createChainDescFor(token: token)
        return cryptoSender.canSendCrypto(chainDesc: chainDesc)
    }
    
    private func createChainDescFor(token: BalanceTokenUIDescription) -> CryptoSenderChainDescription {
        CryptoSenderChainDescription(symbol: token.symbol,
                              chain: token.chain,
                              env: getCurrentEnvironment())
    }
    
    func sendCryptoTokenWith(sendData: SendCryptoAsset.SendTokenAssetData,
                             txSpeed: SendCryptoAsset.TransactionSpeed) async throws -> String {
        let amount: Double
        if sendData.isSendingAllTokens() {
            amount = try await getMaxTokenAmountToSendConsideringGasFee(sendData: sendData, txSpeed: txSpeed)
        } else {
            amount = sendData.getTokenAmountValueToSend()
        }
        let dataToSend = getCryptoDataToSendFor(sendData: sendData,
                                                txSpeed: txSpeed,
                                                amount: amount)

        return try await cryptoSender.sendCrypto(dataToSend: dataToSend)
    }
    
    private func getMaxTokenAmountToSendConsideringGasFee(sendData: SendCryptoAsset.SendTokenAssetData,
                                                          txSpeed: SendCryptoAsset.TransactionSpeed) async throws -> Double {
        let gasPrice = try await computeGasFeeFor(sendData: sendData, txSpeed: txSpeed)
        let tokenAmountToSend = sendData.getTokenAmountValueToSend() - gasPrice
        guard tokenAmountToSend > 0 else {
            throw CryptoSender.Error.insufficientFunds
        }
        
        return tokenAmountToSend
    }
    
    func computeGasFeeFor(sendData: SendCryptoAsset.SendTokenAssetData,
                          txSpeed: SendCryptoAsset.TransactionSpeed) async throws -> Double {
        let dataToSend = getCryptoDataToSendFor(sendData: sendData, txSpeed: txSpeed)
        
        return try await cryptoSender.computeGasFeeFor(dataToSend: dataToSend).units
    }
    
    func getGasPrices(sendData: SendCryptoAsset.SendTokenAssetData) async throws -> EstimatedGasPrices {
        let chainDesc = createChainDescFor(token: sendData.token)

        return try await cryptoSender.fetchGasPrices(chainDesc: chainDesc)
    }
    
    private func getCryptoDataToSendFor(sendData: SendCryptoAsset.SendTokenAssetData,
                                        txSpeed: SendCryptoAsset.TransactionSpeed,
                                        amount: Double? = nil) -> CryptoSenderDataToSend {
        let speed = getSpecTransactionSpeedFor(txSpeed: txSpeed)
        let amount = amount ?? sendData.getTokenAmountValueToSend()
        let token = sendData.token
        let chainDesc = createChainDescFor(token: token)
        let toAddress = sendData.receiverAddress
        let dataToSend = CryptoSenderDataToSend(chainDesc: chainDesc,
                                                amount: amount,
                                                txSpeed: speed,
                                                toAddress: toAddress)
        
        return dataToSend
    }
    
    private func getCurrentEnvironment() -> UnsConfigManager.BlockchainEnvironment {
        User.instance.getSettings().isTestnetUsed ? .testnet : .mainnet
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
