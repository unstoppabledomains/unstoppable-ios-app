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
        
        case userTokenSelected(BalanceTokenUIDescription)
        case userTokenValueSelected(BalanceTokenUIDescription)
        
        case userDomainSelected(DomainDisplayInfo)
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
//    struct SelectAssetToSend
}

extension SendCryptoAsset {
    enum TokenAssetAmountInputType {
        case usdAmount
        case tokenAmount
    }
    
    enum TokenAssetAmountInput {
        case usdAmount(Double)
        case tokenAmount(Double)
    }
}
