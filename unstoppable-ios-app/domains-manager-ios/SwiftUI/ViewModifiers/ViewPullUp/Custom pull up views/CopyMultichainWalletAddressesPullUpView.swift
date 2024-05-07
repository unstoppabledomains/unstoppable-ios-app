//
//  CopyMultichainWalletAddressesPullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.05.2024.
//

import SwiftUI

struct CopyMultichainWalletAddressesPullUpView: View {
    
    let tokens: [BalanceTokenUIDescription]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView()
                cryptoListView()
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .background(Color.backgroundDefault)
    }
}

// MARK: - Private methods
private extension CopyMultichainWalletAddressesPullUpView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            DismissIndicatorView()
            Text("MPC Wallet has addresses across multiple blockchains")
                .font(.currentFont(size: 22, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }
    
    @ViewBuilder
    func cryptoListView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(tokens, id: \.id) { token in
                    listViewFor(token: token)
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(token: BalanceTokenUIDescription) -> some View {
        TokenSelectionRowView(token: token)
            .udListItemInCollectionButtonPadding()
        .padding(EdgeInsets(4))
    }
}

// MARK: - Private methods
private extension CopyMultichainWalletAddressesPullUpView {
    struct TokenSelectionRowView: View {
        
        let token: BalanceTokenUIDescription
        @State private var icon: UIImage? 
        
        var body: some View {
            UDListItemView(title: token.name,
                           subtitle: token.address,
                           subtitleStyle: .default,
                           imageType: .uiImage(icon ?? .init()),
                           imageStyle: .full,
                           rightViewStyle: nil)
            .onAppear(perform: onAppear)
        }
        
        private func onAppear() {
            loadTokenIcon()
        }
        
        private func loadTokenIcon() {
                token.loadTokenIcon { image in
                    self.icon = image
                }
        }
    }
}

#Preview {
    CopyMultichainWalletAddressesPullUpView(tokens: [MockEntitiesFabric.Tokens.mockEthToken(),
                                                     MockEntitiesFabric.Tokens.mockMaticToken()])
}
