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
        .background(Color.backgroundDefault)
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
        if !wallets.isEmpty {
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
    }
    
    @ViewBuilder
    func listViewFor(wallet: WalletEntity) -> some View {
        HomeWalletWalletSelectionRowView(wallet: wallet, 
                                         isSelected: wallet.address == selectedWallet?.address )
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
