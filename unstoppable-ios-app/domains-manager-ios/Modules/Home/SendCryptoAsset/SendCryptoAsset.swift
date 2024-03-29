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
        case globalWalletAddressSelected(HexAddress)
        
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
        let domainName: DomainName?
        let pfpURL: URL?
        
        init(wallet: WalletEntity) {
            self.walletAddress = wallet.address
            self.domainName = wallet.rrDomain?.name
            self.pfpURL = wallet.rrDomain?.pfpSource.value.asURL
        }
        
        init(followingDomain profile: DomainProfileDisplayInfo) {
            self.walletAddress = profile.ownerWallet
            self.domainName = profile.domainName
            self.pfpURL = profile.pfpURL
        }
        
        init?(globalProfile: SearchDomainProfile) {
            guard let walletAddress = globalProfile.ownerAddress else {
                Debugger.printFailure("Failed to create crypto asset receiver with SearchDomainProfile \(globalProfile.name)", critical: true)
                return nil
            }
            self.walletAddress = walletAddress
            self.domainName = globalProfile.name
            self.pfpURL = globalProfile.imagePath?.asURL
        }
        
        init(walletAddress: HexAddress) {
            self.walletAddress = walletAddress
            self.domainName = nil
            self.pfpURL = nil
        }
    }
}

extension SendCryptoAsset {
    struct SelectTokenAmountToSendData: Hashable {
        let receiver: AssetReceiver
        let token: BalanceTokenUIDescription
    }
    
    struct SendTokenAssetData: Hashable {
        let receiver: AssetReceiver
        let token: BalanceTokenUIDescription
        let amount: TokenAssetAmountInput
        
        var receiverAddress: HexAddress {
            receiver.walletAddress
        }
        
        func getTokenAmountValueToSend() -> Double {
            amount.valueOf(type: .tokenAmount, for: token)
        }
        
        func isSendingAllTokens() -> Bool {
            getTokenAmountValueToSend() >= token.balance
        }
    }
    
    enum TransactionSpeed: CaseIterable {
        case normal, fast, urgent
        
        var title: String {
            switch self {
            case .normal:
                return "Normal"
            case .fast:
                return "Fast"
            case .urgent:
                return "Urgent"
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
