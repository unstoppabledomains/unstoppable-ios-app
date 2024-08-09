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
    @Environment(\.userProfilesService) private var userProfilesService

    @State var selectedWallet: WalletEntity
    let wallets: [WalletEntity]
    let selectedWalletCallback: PurchaseDomainSelectWalletCallback
    var analyticsName: Analytics.ViewName { analyticsViewName }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(String.Constants.purchaseMintingWalletPullUpTitle.localized())
                            .textAttributes(color: .foregroundDefault,
                                            fontSize: 22,
                                            fontWeight: .bold)
                        Text(String.Constants.purchaseMintingWalletPullUpSubtitle.localized())
                            .textAttributes(color: .foregroundSecondary,
                                            fontSize: 16)
                    }
                    .multilineTextAlignment(.center)
                    UDCollectionSectionBackgroundView {
                        VStack {
                            ForEach(wallets, id: \.address) { wallet in
                                walletRowView(wallet)
                            }
                        }
                        .padding(4)
                    }
                }
            }
            UDButtonView(text: String.Constants.doneButtonTitle.localized(),
                         style: .large(.raisedPrimary)) {
                userProfilesService.setActiveProfile(.wallet(selectedWallet))
                selectedWalletCallback(selectedWallet)
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding(EdgeInsets(top: 32, leading: 16, bottom: 16, trailing: 16))
        .background(Color.backgroundDefault)
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
            .udListItemInCollectionButtonPadding()
        }, callback: {
            logButtonPressedAnalyticEvents(button: .purchaseDomainTargetWalletSelected)
            self.selectedWallet = wallet
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
