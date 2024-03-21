//
//  ConfirmSendTokenView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2024.
//

import SwiftUI

struct ConfirmSendTokenView: View {
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel

    let token: BalanceTokenUIDescription

    var body: some View {
        VStack {
            sendingTokenInfoView()
        }
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenView {
    @ViewBuilder
    func sendingTokenInfoView() -> some View {
        ZStack {
            Image.confirmSendTokenGrid
                .resizable()
                .frame(height: 92)
            HStack(spacing: 16) {
                BalanceTokenIconsView(token: token)
                tokenSendingValuesView()
                Spacer()
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.05, green: 0.4, blue: 1).opacity(0), location: 0.25),
                    Gradient.Stop(color: Color(red: 0.05, green: 0.4, blue: 1).opacity(0.16), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.foregroundAccent, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    func tokenSendingValuesView() -> some View {
        VStack(spacing: 0) {
            Text(token.formattedBalanceUSD)
                .font(.currentFont(size: 28, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
                .frame(height: 36)
            Text(token.formattedBalanceWithSymbol)
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
                .frame(height: 24)
        }
    }
}

#Preview {
    NavigationStack {
        ConfirmSendTokenView(token: MockEntitiesFabric.Tokens.mockUIToken())
    }
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
