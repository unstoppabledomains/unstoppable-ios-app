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
    
    @State private var receiverAvatar: UIImage?

    var body: some View {
        VStack(spacing: 4) {
            sendingTokenInfoView()
            senderReceiverConnectorView()
            receiverInfoView()
            reviewInfoView()
            Spacer()
        }
        .padding(16)
        .background(Color.backgroundDefault)
        .animation(.default, value: UUID())
        .addNavigationTopSafeAreaOffset()
        .navigationTitle(String.Constants.send.localized())
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenView {
    @ViewBuilder
        func sendingTokenInfoView() -> some View {
            ZStack {
                Image.confirmSendTokenGrid
                    .resizable()
                    .frame(height: 60)
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
            primaryTextView(token.formattedBalanceUSD)
            secondaryTextView(token.formattedBalanceWithSymbol)
        }
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenView {
    @ViewBuilder
    func receiverInfoView() -> some View {
        HStack(spacing: 16) {
            UIImageBridgeView(image: receiverAvatar ?? .domainSharePlaceholder)
                .squareFrame(40)
                .clipShape(Circle())
            receiverAddressInfoView()
            Spacer()
        }
        .padding(16)
        .background(Color.backgroundOverlay)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderMuted, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    func receiverAddressInfoView() -> some View {
        VStack(spacing: 0) {
            primaryTextView(token.formattedBalanceUSD)
            secondaryTextView(token.formattedBalanceWithSymbol)
        }
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenView {
    @ViewBuilder
    func senderReceiverConnectorView() -> some View {
        ConfirmSendTokenSenderReceiverConnectView()
    }
    
    @ViewBuilder
    func reviewInfoView() -> some View {
        ConfirmSendTokenReviewInfoView()
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenView {
    @ViewBuilder
    func primaryTextView(_ text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 28, weight: .medium))
            .foregroundStyle(Color.foregroundDefault)
            .frame(height: 36)
    }
    
    @ViewBuilder
    func secondaryTextView(_ text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 16))
            .foregroundStyle(Color.foregroundSecondary)
            .frame(height: 24)
    }
}

#Preview {
    NavigationStack {
        ConfirmSendTokenView(token: MockEntitiesFabric.Tokens.mockUIToken())
            .navigationBarTitleDisplayMode(.inline)
    }
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
