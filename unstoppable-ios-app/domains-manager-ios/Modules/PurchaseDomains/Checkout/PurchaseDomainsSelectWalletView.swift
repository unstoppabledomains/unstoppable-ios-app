//
//  PurchaseDomainsSelectWalletView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.11.2023.
//

import SwiftUI

typealias PurchaseDomainSelectWalletCallback = (WalletEntity)->()

struct PurchaseDomainsSelectWalletView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) private var analyticsViewName
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.userProfileService) private var userProfileService

    @State var selectedWallet: WalletEntity
    let wallets: [WalletEntity]
    let selectedWalletCallback: PurchaseDomainSelectWalletCallback
    var analyticsName: Analytics.ViewName { analyticsViewName }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(String.Constants.mintTo.localized())
                    .font(.currentFont(size: 22, weight: .bold))
                    .foregroundStyle(Color.foregroundDefault)
                    .multilineTextAlignment(.center)
                UDCollectionSectionBackgroundView {
                    LazyVStack {
                        ForEach(wallets, id: \.address) { wallet in
                            walletRowView(wallet)
                        }
                    }
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                }
            }
            .padding(EdgeInsets(top: 32, leading: 16, bottom: 16, trailing: 16))
        }
    }
}

// MARK: - Private methods
private extension PurchaseDomainsSelectWalletView {
    @ViewBuilder
    func walletRowView(_ wallet: WalletEntity) -> some View {
        let walletDisplayInfo = WalletRowDisplayInfo(wallet: wallet.displayInfo,
                                                     isSelected: wallet.address == selectedWallet.address)
        
        UDCollectionListRowButton(content: {
            UDListItemView(title: walletDisplayInfo.title,
                           subtitle: walletDisplayInfo.subtitle,
                           imageType: .image(walletDisplayInfo.image),
                           imageStyle: walletDisplayInfo.imageStyle,
                           rightViewStyle: walletDisplayInfo.rightViewStyle)
        }, callback: {
            logButtonPressedAnalyticEvents(button: .purchaseDomainTargetWalletSelected)

            let selectedWallet = wallet
            self.selectedWallet = selectedWallet
            userProfileService.setSelectedProfile(.wallet(selectedWallet))
            selectedWalletCallback(selectedWallet)
            presentationMode.wrappedValue.dismiss()
        })
    }
    
    struct WalletRowDisplayInfo {
        let title: String
        let subtitle: String?
        let image: Image
        let imageStyle: UDListItemView.ImageStyle
        let rightViewStyle: UDListItemView.RightViewStyle?
        
        init(wallet: WalletDisplayInfo,
             isSelected: Bool) {
            title = wallet.displayName
            var subtitle: String?
            if wallet.isNameSet {
                subtitle = "\(wallet.address.walletAddressTruncated)"
            }
            if wallet.domainsCount > 0 {
                let domainsCounterText = String.Constants.pluralNDomains.localized(wallet.domainsCount, wallet.domainsCount)
                if wallet.isNameSet {
                    subtitle! += " · \(domainsCounterText)"
                } else {
                    subtitle = domainsCounterText
                }
            }
            self.subtitle = subtitle
            image = Image(uiImage: wallet.source.displayIcon)
            if wallet.source == .imported {
                imageStyle = .centred()
            } else {
                imageStyle = .full
            }
            rightViewStyle = isSelected ? .checkmark : nil
        }
    }
}

#Preview {
    PurchaseDomainsSelectWalletView(selectedWallet: MockEntitiesFabric.Wallet.mockEntities()[0], wallets: MockEntitiesFabric.Wallet.mockEntities(), selectedWalletCallback: { _ in })
}
