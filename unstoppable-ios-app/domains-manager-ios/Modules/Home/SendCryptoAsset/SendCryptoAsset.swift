//
//  SendCryptoAsset.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import Foundation

enum SendCryptoAsset { }

extension SendCryptoAsset {
    struct InitialData: Identifiable {
        
        var id: String { sourceWallet.id }
        
        let sourceWallet: WalletEntity
    }
}

extension SendCryptoAsset {
    enum AssetType: String, Identifiable, CaseIterable, UDTabPickable {
        
        var id: String { rawValue }
        
        case tokens, domains
        
        var title: String {
            switch self {
            case .tokens:
                String.Constants.tokens.localized()
            case .domains:
                String.Constants.domains.localized()
            }
        }
    }
}

extension SendCryptoAsset {
    enum FlowAction {
        case scanQRSelected
        case userWalletSelected(WalletEntity)
        case followingDomainSelected(DomainProfileDisplayInfo)
        case globalProfileSelected(SearchDomainProfile)
        case globalWalletAddressSelected(SendCryptoAsset.WalletAddressDetails)
        
        case userTokenToSendSelected(SelectTokenAmountToSendData)
        case userTokenValueSelected(SendTokenAssetData)
        case didSendCrypto(data: SendTokenAssetData, txHash: String)
        
        case userDomainSelected(TransferDomainData)
        case didTransferDomain(DomainDisplayInfo)
    }
}

extension SendCryptoAsset {
    struct AssetReceiver: Hashable {
        let walletAddress: String
        let network: BlockchainType
        let domainName: DomainName?
        private(set) var pfpURL: URL?
        private var records: [String: String] = [:]
        
        func addressFor(token: BalanceTokenUIDescription,
                        in currencies: [CoinRecord]) -> String? {
            let coinRecords = currencies.filter { $0.ticker == token.symbol }
            let chain = resolveCoinRecordChainIdentifier(token.chain)
            guard let tokenRecord = coinRecords.first(where: { record in
                if record.version == nil {
                    return token.chain == token.symbol
                }
                return record.version == chain    
            }) else { return nil }
            
            let recordsIdentifier = tokenRecord.expandedTicker
            return self.records[recordsIdentifier]
        }
        
        private func resolveCoinRecordChainIdentifier(_ chain: String) -> String {
            switch chain {
            case BlockchainType.Ethereum.shortCode:
                return "ERC20"
            default:
                return chain
            }
        }
        
        init(wallet: WalletEntity) async throws {
            self.walletAddress = wallet.address
            self.domainName = wallet.rrDomain?.name
            self.pfpURL = wallet.rrDomain?.pfpSource.value.asURL
            self.network = .Ethereum
            try await loadRecords()
        }
        
        init(followingDomain profile: DomainProfileDisplayInfo) async throws {
            self.walletAddress = profile.ownerWallet
            self.domainName = profile.domainName
            self.pfpURL = profile.pfpURL
            self.network = .Ethereum
            try await loadRecords()
        }
        
        init(globalProfile: SearchDomainProfile) async throws {
            guard let walletAddress = globalProfile.ownerAddress else {
                Debugger.printFailure("Failed to create crypto asset receiver with SearchDomainProfile \(globalProfile.name)", critical: true)
                throw AssetReceiverError.noWalletAddress
            }
            self.walletAddress = walletAddress
            self.domainName = globalProfile.name
            self.pfpURL = globalProfile.imagePath?.asURL
            self.network = .Ethereum
            try await loadRecords()
        }
        
        init(walletAddress: HexAddress,
             network: BlockchainType) {
            self.walletAddress = walletAddress
            self.domainName = nil
            self.pfpURL = nil
            self.network = network
        }
        
        mutating private func loadRecords() async throws {
            guard let domainName else { return }
            
            let profile = try await appContext.domainProfilesService.fetchDomainProfileDisplayInfo(for: domainName)
            self.records = profile.records 
            self.pfpURL = profile.pfpURL
        }
        
        enum AssetReceiverError: String, LocalizedError {
            case noWalletAddress
            
            public var errorDescription: String? {
                return rawValue
            }
        }
    }
}

extension SendCryptoAsset {
    struct SelectTokenAmountToSendData: Hashable {
        let receiver: AssetReceiver
        let token: BalanceTokenUIDescription
        let receiverAddress: HexAddress
    }
    
    struct SendTokenAssetData: Hashable {
        let receiver: AssetReceiver
        let token: BalanceTokenUIDescription
        let amount: TokenAssetAmountInput
        let receiverAddress: HexAddress
        
        func getTokenAmountValueToSend() -> Double {
            amount.valueOf(type: .tokenAmount, for: token)
        }
        
        func isSendingAllTokens() -> Bool {
            getTokenAmountValueToSend() >= token.balance
        }
    }
    
    enum TransactionSpeed: String, CaseIterable {
        case normal, fast, urgent
        
        var title: String {
            switch self {
            case .normal:
                return String.Constants.normal.localized()
            case .fast:
                return String.Constants.fast.localized()
            case .urgent:
                return String.Constants.urgent.localized()
            }
        }
        
        var iconName: String {
            switch self {
            case .normal:
                "clock"
            case .fast:
                "bolt"
            case .urgent:
                "flame"
            }
        }
      
    }
}

extension SendCryptoAsset {
    struct TransferDomainData: Hashable {
        let receiver: AssetReceiver
        let domain: DomainDisplayInfo
    }
    
    struct TransferDomainConfirmationData {
        let shouldClearRecords: Bool
    }
}

extension SendCryptoAsset {
    struct WalletAddressDetails {
        let address: String
        let network: BlockchainType
    }
}

extension SendCryptoAsset {
    enum TokenAssetAmountInputType {
        case usdAmount
        case tokenAmount
    }
    
    enum TokenAssetAmountInput: Hashable {
        case usdAmount(Double)
        case tokenAmount(Double)
        
        func valueOf(type: TokenAssetAmountInputType,
                     for token: BalanceTokenUIDescription) -> Double {
            switch (self, type) {
                case (.usdAmount(let usdAmount), .usdAmount):
                    return usdAmount
                case (.tokenAmount(let tokenAmount), .tokenAmount):
                    return tokenAmount
                case (.usdAmount(let usdAmount), .tokenAmount):
                    return usdAmount / (token.marketUsd ?? 1)
                case (.tokenAmount(let tokenAmount), .usdAmount):
                    return tokenAmount * (token.marketUsd ?? 1)
            }
        }
    }
}

extension SendCryptoAsset {
    struct Constants {
        @MainActor
        static var tilesVerticalPadding: CGFloat { deviceSize.isIPSE ? 8 : 16 }
    }
}
