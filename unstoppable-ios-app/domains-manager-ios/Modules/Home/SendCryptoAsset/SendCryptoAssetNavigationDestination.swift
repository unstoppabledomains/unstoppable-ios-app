//
//  SendCryptoAssetNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

extension SendCryptoAsset {
    enum NavigationDestination: Hashable {
        case scanWalletAddress
        case selectAssetToSend(AssetReceiver)
        case selectTokenAmountToSend(SelectTokenAmountToSendData)
        case confirmSendToken(SendTokenAssetData)
        case cryptoSendSuccess(data: SendTokenAssetData, txHash: String)
        
        case confirmTransferDomain(TransferDomainData)
        case domainTransferSuccess(DomainDisplayInfo)
        
        var isWithCustomTitle: Bool {
            switch self {
            case .selectTokenAmountToSend, .selectAssetToSend:
                return true
            case .scanWalletAddress, .confirmTransferDomain, .domainTransferSuccess, .confirmSendToken, .cryptoSendSuccess:
                return false
            }
        }
    }
    
    struct LinkNavigationDestination {
        
        @ViewBuilder
        static func viewFor(navigationDestination: NavigationDestination) -> some View {
            switch navigationDestination {
            case .scanWalletAddress:
                SendCryptoQRWalletAddressScannerView()
            case .selectAssetToSend(let receiver):
                SelectCryptoAssetToSendView(receiver: receiver)
            case .selectTokenAmountToSend(let data):
                SelectTokenAssetAmountToSendView(data: data)
            case .confirmSendToken(let data):
                ConfirmSendTokenView(data: data)
            case .cryptoSendSuccess(let data, let txHash):
                SendCryptoAssetSuccessView(asset: .token(token: data.token,
                                                         amount: data.amount,
                                                         txHash: txHash))
                
            case .confirmTransferDomain(let data):
                ConfirmTransferDomainView(data: data)
            case .domainTransferSuccess(let domain):
                SendCryptoAssetSuccessView(asset: .domain(domain))
            }
        }
        
    }
}
