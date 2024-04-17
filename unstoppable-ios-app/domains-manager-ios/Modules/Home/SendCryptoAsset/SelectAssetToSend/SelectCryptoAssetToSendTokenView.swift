//
//  SelectCryptoAssetToSendTokenView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectCryptoAssetToSendTokenView: View {
    
    let token: BalanceTokenUIDescription
    
    var body: some View {
        HStack(spacing: 16) {
            BalanceTokenIconsView(token: token)
            tokenInfoView()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Private methods
private extension SelectCryptoAssetToSendTokenView {
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
