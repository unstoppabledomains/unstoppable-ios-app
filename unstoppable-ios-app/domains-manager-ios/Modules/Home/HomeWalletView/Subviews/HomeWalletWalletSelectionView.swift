//
//  HomeWalletWalletSelectionView:.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct HomeWalletWalletSelectionView: View {
    
    @State private var wallets: [WalletWithInfo] = []
    @State private var selectedWallet: WalletWithInfo? = nil
    var walletSelectedCallback: (WalletWithInfo)->()
    
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
        Task {
            let wallets = await appContext.dataAggregatorService.getWalletsWithInfo()
            self.selectedWallet = wallets.first
            self.wallets = wallets.filter({ $0.address != selectedWallet?.address })
        }
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
                        
                    } label: {
                        listViewFor(wallet: wallet)
                    }
                }
            }
        }
    }
    
    func isWalletAbleToSetRR(_ wallet: WalletWithInfo) -> Bool {
        (wallet.displayInfo?.udDomainsCount ?? 0) > 0
    }
    
    @ViewBuilder
    func listViewFor(wallet: WalletWithInfo) -> some View {
        UDListItemView(title: titleForWallet(wallet),
                       subtitle: subtitleForWallet(wallet),
                       subtitleStyle: subtitleStyleForWallet(wallet),
                       imageType: imageTypeForWallet(wallet),
                       rightViewStyle: wallet.address == selectedWallet?.address ? .checkmark : nil)
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
   
    func titleForWallet(_ wallet: WalletWithInfo) -> String {
        if let rrDomain = wallet.displayInfo?.reverseResolutionDomain {
            return rrDomain.name
        }
        return wallet.displayName
    }
    
    func subtitleForWallet(_ wallet: WalletWithInfo) -> String? {
        if wallet.displayInfo?.reverseResolutionDomain != nil {
            if wallet.displayInfo?.isNameSet == true {
                return "\(wallet.displayName) · \(wallet.address.walletAddressTruncated)"
            }
            return wallet.address.walletAddressTruncated
        }
        if isWalletAbleToSetRR(wallet) {
            return "No primary domain"
        }
        return nil
    }
    
    func subtitleStyleForWallet(_ wallet: WalletWithInfo) -> UDListItemView.SubtitleStyle {
        if wallet.displayInfo?.reverseResolutionDomain == nil,
           isWalletAbleToSetRR(wallet) {
            return .warning
        }
         return .default
    }
    
    func imageTypeForWallet(_ wallet: WalletWithInfo) -> UDListItemView.ImageType {
        if let rrDomain = wallet.displayInfo?.reverseResolutionDomain,
           let avatar = appContext.imageLoadingService.cachedImage(for: .domain(rrDomain)) {
            return .uiImage(avatar)
        }
        switch wallet.wallet.type {
        case .defaultGeneratedLocally, .generatedLocally:
            return .image(.vaultSafeIcon)
        default:
            return .image(.walletExternalIcon)
        }
    }
    
    @ViewBuilder
    func addWalletView() -> some View {
        UDCollectionSectionBackgroundView {
            Button {
                
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
    HomeWalletWalletSelectionView(walletSelectedCallback: { _ in })
}
