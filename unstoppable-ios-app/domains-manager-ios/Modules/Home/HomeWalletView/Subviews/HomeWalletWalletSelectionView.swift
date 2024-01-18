//
//  HomeWalletWalletSelectionView:.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct HomeWalletWalletSelectionView: View {
    
    @Environment(\.walletsDataService) private var walletsDataService
    @Environment(\.presentationMode) private var presentationMode

    @State private var wallets: [WalletEntity] = []
    @State private var selectedWallet: WalletEntity? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                titleView()
                selectedWalletView()
                walletsListView()
                addWalletView()
            }
            .padding()
        }
        .onAppear(perform: onAppear)
    }
    
    
}

// MARK: - Private methods
private extension HomeWalletWalletSelectionView {
    func onAppear() {
        let wallets = walletsDataService.wallets
        self.selectedWallet = walletsDataService.selectedWallet
        self.wallets = wallets.filter({ $0.address != selectedWallet?.address })
    }
    
    @ViewBuilder
    func titleView() -> some View {
        Text("Profiles")
            .font(.currentFont(size: 22, weight: .bold))
            .foregroundStyle(Color.foregroundDefault)
            .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
    }
    
    @ViewBuilder
    func selectedWalletView() -> some View {
        if let selectedWallet {
            UDCollectionSectionBackgroundView {
                listViewFor(wallet: selectedWallet)
            }
        }
    }
    
    @ViewBuilder
    func walletsListView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(wallets, id: \.address) { wallet in
                    Button {
                        UDVibration.buttonTap.vibrate()
                        presentationMode.wrappedValue.dismiss()
                        walletsDataService.setSelectedWallet(wallet)
                    } label: {
                        listViewFor(wallet: wallet)
                    }
                }
            }
        }
    }
    
    func isWalletAbleToSetRR(_ wallet: WalletEntity) -> Bool {
        wallet.displayInfo.udDomainsCount > 0
    }
    
    @ViewBuilder
    func listViewFor(wallet: WalletEntity) -> some View {
        UDListItemView(title: titleForWallet(wallet),
                       subtitle: subtitleForWallet(wallet),
                       subtitleStyle: subtitleStyleForWallet(wallet),
                       imageType: imageTypeForWallet(wallet),
                       imageStyle: imageStyleForWallet(wallet),
                       rightViewStyle: wallet.address == selectedWallet?.address ? .checkmark : nil)
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
        if let rrDomain = wallet.rrDomain,
           let avatar = appContext.imageLoadingService.cachedImage(for: .domain(rrDomain)) {
            return .uiImage(avatar)
        }
        switch wallet.udWallet.type {
        case .defaultGeneratedLocally, .generatedLocally:
            return .image(.vaultSafeIcon)
        default:
            return .image(.walletExternalIcon)
        }
    }
    
    func imageStyleForWallet(_ wallet: WalletEntity) -> UDListItemView.ImageStyle {
        if let rrDomain = wallet.rrDomain,
           let avatar = appContext.imageLoadingService.cachedImage(for: .domain(rrDomain)) {
            return .full
        }
        return .centred()
    }
    
    @ViewBuilder
    func addWalletView() -> some View {
        UDCollectionSectionBackgroundView {
            Button {
                UDVibration.buttonTap.vibrate()
            } label: {
                HStack(spacing: 16) {
                    Image.plusIconNav
                        .resizable()
                        .squareFrame(20)
                    
                    Text(String.Constants.add.localized())
                        .font(.currentFont(size: 16, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(Color.foregroundAccent)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
                .frame(height: 56)
            }
        }
    }
}

#Preview {
    HomeWalletWalletSelectionView()
}
