//
//  SelectCryptoAssetToSendTokenView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectCryptoAssetToSendTokenView: View {
    
    let token: BalanceTokenUIDescription
    
    @State private var icon: UIImage?
    @State private var parentIcon: UIImage?
    
    var body: some View {
        HStack(spacing: 16) {
            iconView()
            tokenInfoView()
        }
            .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension SelectCryptoAssetToSendTokenView {
    func onAppear() {
        loadIconFor(token: token)
    }
    
    func loadIconFor(token: BalanceTokenUIDescription) {
        token.loadTokenIcon { image in
            self.icon = image
        }
        token.loadParentIcon { image in
            self.parentIcon = image
        }
    }
}

// MARK: - Private methods
private extension SelectCryptoAssetToSendTokenView {
    @ViewBuilder
    func iconView() -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: icon ?? .init())
                .resizable()
                .squareFrame(40)
                .background(Color.backgroundSubtle)
                .skeletonable()
                .clipShape(Circle())
            
            if token.parentSymbol != nil {
                Image(uiImage: parentIcon ?? .init())
                    .resizable()
                    .squareFrame(20)
                    .background(Color.backgroundDefault)
                    .skeletonable()
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(lineWidth: 2)
                            .foregroundStyle(Color.backgroundDefault)
                    }
                    .offset(x: 4, y: 4)
            }
        }
    }
    
    @ViewBuilder
    func tokenInfoView() -> some View {
        HStack(spacing: 0) {
            tokenNameAndBalance()
            Spacer()
            tokenBalanceUSD()
        }
    }
    
    @ViewBuilder
    func tokenNameAndBalance() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(token.name)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
            Text(token.formattedBalanceWithSymbol)
                .font(.currentFont(size: 14))
                .foregroundStyle(Color.foregroundSecondary)
        }
    }
    
    @ViewBuilder
    func tokenBalanceUSD() -> some View {
        Text(token.formattedBalanceUSD)
            .font(.currentFont(size: 16, weight: .medium))
            .foregroundStyle(Color.foregroundDefault)
    }
}

#Preview {
    SelectCryptoAssetToSendTokenView(token: MockEntitiesFabric.Tokens.mockUIToken())
}
