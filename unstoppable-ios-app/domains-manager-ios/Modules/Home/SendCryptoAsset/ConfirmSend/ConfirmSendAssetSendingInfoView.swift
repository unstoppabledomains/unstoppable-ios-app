//
//  ConfirmSendAssetSendingInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

struct ConfirmSendAssetSendingInfoView: View, ConfirmSendTokenViewsBuilderProtocol {
    
    let asset: Asset
    
    var body: some View {
        sendingTokenInfoView()
    }
}

// MARK: - Private methods
private extension ConfirmSendAssetSendingInfoView {
    @MainActor
    @ViewBuilder
    func sendingTokenInfoView() -> some View {
        ZStack {
            Image.confirmSendTokenGrid
                .resizable()
                .frame(height: 60)
            HStack(spacing: 16) {
                currentAssetContent()
                Spacer()
            }
        }
        .padding(.init(horizontal: 16, vertical: SendCryptoAsset.Constants.tilesVerticalPadding))
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
}

// MARK: - Private methods
private extension ConfirmSendAssetSendingInfoView {
    @ViewBuilder
    func currentAssetContent() -> some View {
        switch asset {
        case .token(let token, _):
            BalanceTokenIconsView(token: token)
        }
        tokenSendingValuesView()
    }
    
    var currentTitle: String {
        switch asset {
        case.token(let token, let amount):
            formatCartPrice(amount.valueOf(type: .usdAmount,
                                           for: token))
        }
    }
    
    var currentSubtitle: String {
        switch asset {
        case.token(let token, let amount):
            BalanceStringFormatter.tokenFullBalanceString(balance: amount.valueOf(type: .tokenAmount,
                                                                                  for: token),
                                                          symbol: token.symbol)
        }
    }
    
    @ViewBuilder
    func tokenSendingValuesView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            primaryTextView(currentTitle)
            secondaryTextView(currentSubtitle)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

// MARK: - Open methods
extension ConfirmSendAssetSendingInfoView {
    enum Asset {
        case token(token: BalanceTokenUIDescription, amount: SendCryptoAsset.TokenAssetAmountInput)
    }
}

#Preview {
    ConfirmSendAssetSendingInfoView(asset: .token(token: MockEntitiesFabric.Tokens.mockUIToken(),
                                                  amount: .usdAmount(10)))
}
