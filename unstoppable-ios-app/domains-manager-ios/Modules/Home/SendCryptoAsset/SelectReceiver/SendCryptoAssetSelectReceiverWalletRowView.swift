//
//  SendCryptoSelectReceiverWalletRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SendCryptoAssetSelectReceiverWalletRowView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    let wallet: WalletEntity
    @State private var domainAvatarImage: UIImage?

    var body: some View {
        UDListItemView(title: wallet.displayName,
                       titleColor: .foregroundDefault,
                       subtitle: subtitle,
                       subtitleStyle: .default,
                       value: nil,
                       imageType: imageTypeForWallet(),
                       imageStyle: imageStyleForWallet(),
                       rightViewStyle: nil)
    }
}

// MARK: - Private methods
private extension SendCryptoAssetSelectReceiverWalletRowView {
    func onAppear() {
        guard let rrDomain = wallet.rrDomain else {
            domainAvatarImage = nil
            return }
        
        if let avatar = appContext.imageLoadingService.cachedImage(for: .domain(rrDomain),
                                                                   downsampleDescription: .icon) {
            self.domainAvatarImage = avatar
        } else {
            Task {
                domainAvatarImage = await imageLoadingService.loadImage(from: .domain(rrDomain),
                                                                        downsampleDescription: .icon)
            }
        }
    }
    
    var subtitle: String {
        BalanceStringFormatter.tokensBalanceString(wallet.totalBalance)
    }
    
    func imageTypeForWallet() -> UDListItemView.ImageType {
        if let domainAvatarImage {
            return .uiImage(domainAvatarImage)
        }
        switch wallet.udWallet.type {
        case .defaultGeneratedLocally, .generatedLocally:
            return .image(.vaultSafeIcon)
        default:
            return .image(.walletExternalIcon)
        }
    }
    
    func imageStyleForWallet() -> UDListItemView.ImageStyle {
        if domainAvatarImage != nil {
            return .full
        }
        return .centred()
    }
}

#Preview {
    SendCryptoAssetSelectReceiverWalletRowView(wallet: MockEntitiesFabric.Wallet.mockEntities()[0])
}
