//
//  PurchaseDomainsSelectWalletView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.11.2023.
//

import SwiftUI

typealias PurchaseDomainSelectWalletCallback = (WalletWithInfo)->()

struct PurchaseDomainsSelectWalletView: View {
    
    @Environment(\.presentationMode) private var presentationMode

    @State var selectedWallet: WalletWithInfo
    let wallets: [WalletWithInfo]
    let selectedWalletCallback: PurchaseDomainSelectWalletCallback
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(String.Constants.mintTo.localized())
                    .font(.currentFont(size: 22, weight: .bold))
                    .foregroundStyle(Color.foregroundDefault)
                    .multilineTextAlignment(.center)
                UDCollectionSectionBackgroundView {
                    LazyVStack {
                        ForEach(wallets, id: \.wallet.address) { wallet in
                            if let displayInfo = wallet.displayInfo {
                                walletRowView(displayInfo)
                            }
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
    func walletRowView(_ wallet: WalletDisplayInfo) -> some View {
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
        let image = Image(uiImage: wallet.source.displayIcon)
        let imageStyle: UDListItemView.ImageStyle
        if wallet.source == .imported {
            imageStyle = .centred()
        } else {
            imageStyle = .full
        }
        
        return UDCollectionListRowButton(content: {
            UDListItemView(title: wallet.displayName,
                           subtitle: subtitle,
                           image: image,
                           imageStyle: imageStyle,
                           rightViewStyle: wallet.address == selectedWallet.wallet.address ? .checkmark : nil)
        }, callback: {
            guard let selectedWallet = wallets.first(where: { $0.wallet.address == wallet.address }) else { return }
            self.selectedWallet = selectedWallet
            selectedWalletCallback(selectedWallet)
            presentationMode.wrappedValue.dismiss()
        })
    }
}

#Preview {
    PurchaseDomainsSelectWalletView(selectedWallet: WalletWithInfo.mock[0], wallets: WalletWithInfo.mock, selectedWalletCallback: { _ in })
}
