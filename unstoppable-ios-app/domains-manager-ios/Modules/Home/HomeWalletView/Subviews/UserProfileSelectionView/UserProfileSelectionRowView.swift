//
//  UserProfileSelectionRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.01.2024.
//

import SwiftUI

struct UserProfileSelectionRowView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    let profile: UserProfile
    let isSelected: Bool
    
    @State private var domainAvatarImage: UIImage?
    
    var body: some View {
        UDListItemView(title: titleForProfile(profile),
                       subtitle: subtitleForProfile(profile),
                       subtitleStyle: subtitleStyleForProfile(profile),
                       imageType: imageTypeForProfile(profile),
                       imageStyle: imageStyleForProfile(profile),
                       rightViewStyle: isSelected ? .checkmark : nil)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension UserProfileSelectionRowView {
    func onAppear() {
        guard case .wallet(let wallet) = profile,
              let rrDomain = wallet.rrDomain else {
            domainAvatarImage = nil
            return }
        
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
    
    func titleForProfile(_ profile: UserProfile) -> String {
        switch profile {
        case .wallet(let wallet):
            if let rrDomain = wallet.rrDomain {
                return rrDomain.name
            }
            return wallet.displayName
        case .webAccount(let user):
            return user.displayName
        }
    }
    
    func subtitleForProfile(_ profile: UserProfile) -> String? {
        switch profile {
        case .wallet(let wallet):
            if wallet.rrDomain != nil {
                if wallet.displayInfo.isNameSet {
                    return "\(wallet.displayName) · \(wallet.address.walletAddressTruncated)"
                }
                return wallet.address.walletAddressTruncated
            }
            if isWalletAbleToSetRR(wallet) {
                return String.Constants.noPrimaryDomain.localized()
            }
            return nil
        case .webAccount(let user):
            let numberOfDomains = user.numberOfDomains ?? 0
            return String.Constants.pluralNDomains.localized(numberOfDomains, numberOfDomains)
        }
    }
    
    func subtitleStyleForProfile(_ profile: UserProfile) -> UDListItemView.SubtitleStyle {
        switch profile {
        case .wallet(let wallet):
            if wallet.rrDomain == nil,
               isWalletAbleToSetRR(wallet) {
                return .warning
            }
            return .default
        case .webAccount:
            return .default
        }
    }
    
    func imageTypeForProfile(_ profile: UserProfile) -> UDListItemView.ImageType {
        switch profile {
        case .wallet(let wallet):
            if let domainAvatarImage {
                return .uiImage(domainAvatarImage)
            }
            switch wallet.udWallet.type {
            case .defaultGeneratedLocally, .generatedLocally:
                return .image(.vaultSafeIcon)
            default:
                return .image(.walletExternalIcon)
            }
        case .webAccount:
            return .image(.globeIcon)
        }
    }
    
    func imageStyleForProfile(_ profile: UserProfile) -> UDListItemView.ImageStyle {
        switch profile {
        case .wallet(let wallet):
            if domainAvatarImage != nil {
                return .full
            }
            return .centred()
        case .webAccount:
            return .centred()
        }
    }
    
}

#Preview {
    UserProfileSelectionRowView(profile: .wallet(MockEntitiesFabric.Wallet.mockEntities()[0]),
                                isSelected: false)
}
