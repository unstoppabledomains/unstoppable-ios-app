//
//  HomeWalletWalletSelectionRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.01.2024.
//

import SwiftUI

struct HomeWalletWalletSelectionRowView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    let wallet: WalletEntity
    let isSelected: Bool
    
    @State private var domainAvatarImage: UIImage?
    
    var body: some View {
        UDListItemView(title: titleForWallet(wallet),
                       subtitle: subtitleForWallet(wallet),
                       subtitleStyle: subtitleStyleForWallet(wallet),
                       imageType: imageTypeForWallet(wallet),
                       imageStyle: imageStyleForWallet(wallet),
                       rightViewStyle: isSelected ? .checkmark : nil)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension HomeWalletWalletSelectionRowView {
    func onAppear() {
        guard let rrDomain = wallet.rrDomain else { return }
        
        if let avatar = appContext.imageLoadingService.cachedImage(for: .domain(rrDomain)) {
            self.domainAvatarImage = avatar
        } else {
            Task {
                domainAvatarImage = await imageLoadingService.loadImage(from: .domain(rrDomain),
                                                                        downsampleDescription: .icon)
            }
        }
    }
    
    func isWalletAbleToSetRR(_ wallet: WalletEntity) -> Bool {
        wallet.displayInfo.udDomainsCount > 0
    }
    
    func titleForWallet(_ wallet: WalletEntity) -> String {
        if let rrDomain = wallet.rrDomain {
            return rrDomain.name
        }
        return wallet.displayName
    }
    
    func subtitleForWallet(_ wallet: WalletEntity) -> String? {
        if wallet.rrDomain != nil {
            if wallet.displayInfo.isNameSet {
                return "\(wallet.displayName) · \(wallet.address.walletAddressTruncated)"
            }
            return wallet.address.walletAddressTruncated
        }
        if isWalletAbleToSetRR(wallet) {
            return "No primary domain"
        }
        return nil
    }
    
    func subtitleStyleForWallet(_ wallet: WalletEntity) -> UDListItemView.SubtitleStyle {
        if wallet.rrDomain == nil,
           isWalletAbleToSetRR(wallet) {
            return .warning
        }
        return .default
    }
    
    func imageTypeForWallet(_ wallet: WalletEntity) -> UDListItemView.ImageType {
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
    
    func imageStyleForWallet(_ wallet: WalletEntity) -> UDListItemView.ImageStyle {
        if domainAvatarImage != nil {
            return .full
        }
        return .centred()
    }
    
}

#Preview {
    HomeWalletWalletSelectionRowView(wallet: MockEntitiesFabric.Wallet.mockEntities()[0],
                                     isSelected: false)
}
