//
//  ConfirmSendTokenView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2024.
//

import SwiftUI

struct ConfirmSendTokenView: View {
    
    @Environment(\.imageLoadingService) var imageLoadingService
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel

    let data: SendCryptoAsset.SendTokenAssetData
    
    private var token: BalanceTokenUIDescription { data.token }
    private var receiver: SendCryptoAsset.AssetReceiver { data.receiver }
    
    @State private var receiverAvatar: UIImage?

    var body: some View {
        VStack(spacing: 4) {
            sendingTokenInfoView()
            senderReceiverConnectorView()
            receiverInfoView()
            reviewInfoView()
            Spacer()
            confirmButton()
        }
        .padding(16)
        .background(Color.backgroundDefault)
        .animation(.default, value: UUID())
        .addNavigationTopSafeAreaOffset()
        .navigationTitle(String.Constants.youAreSending.localized())
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenView {
    func onAppear() {
        Task {
            if let url = receiver.pfpURL {
                receiverAvatar = await imageLoadingService.loadImage(from: .url(url,
                                                                                maxSize: nil),
                                                                     downsampleDescription: .mid)
            } else if let domainName = receiver.domainName {
                receiverAvatar = await imageLoadingService.loadImage(from: .domainNameInitials(domainName,
                                                                                               size: .default),
                                                                     downsampleDescription: .mid)
            }
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
                    .frame(height: 60)
                HStack(spacing: 16) {
                    BalanceTokenIconsView(token: token)
                    tokenSendingValuesView()
                    Spacer()
                }
            }
            .padding(.init(horizontal: 16, vertical: tilesVerticalPadding))
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
    
    var tilesVerticalPadding: CGFloat { isIPSE ? 8 : 16 }
    var sendingUSDAmount: Double { data.amount.valueOf(type: .usdAmount,
                                                      for: token) }
    var sendingTokenAmount: Double { data.amount.valueOf(type: .tokenAmount,
                                                      for: token) }
    
    
    @ViewBuilder
    func tokenSendingValuesView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            primaryTextView(formatCartPrice(sendingUSDAmount))
            secondaryTextView(BalanceStringFormatter.tokenFullBalanceString(balance: sendingTokenAmount,
                                                                        symbol: token.symbol))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
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
        .padding(.init(horizontal: 16, vertical: tilesVerticalPadding))
        .background(Color.backgroundOverlay)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderMuted, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    func receiverAddressInfoView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let name = receiver.domainName {
                primaryTextView(name)
                secondaryTextView(receiver.walletAddress.walletAddressTruncated)
            } else {
                primaryTextView(receiver.walletAddress.walletAddressTruncated)
            }
        }
        .frame(height: 60)
        .lineLimit(1)
        .minimumScaleFactor(Constants.domainNameMinimumScaleFactor)
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
        ConfirmSendTokenReviewInfoView(token: token,
                                       sourceWallet: viewModel.sourceWallet)
    }
    
    @ViewBuilder
    func confirmButton() -> some View {
        UDButtonView(text: String.Constants.confirm.localized(),
                     icon: confirmIcon,
                     style: .large(.raisedPrimary)) {
            
        }
    }
    
    var confirmIcon: Image? {
        if User.instance.getSettings().touchIdActivated,
           let icon = appContext.authentificationService.biometricIcon {
            return Image(uiImage: icon)
        }
        return nil
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
        ConfirmSendTokenView(data: .init(receiver: MockEntitiesFabric.SendCrypto.mockReceiver(),
                                         token: MockEntitiesFabric.Tokens.mockUIToken(),
                                         amount: .usdAmount(3998234.3)))
            .navigationBarTitleDisplayMode(.inline)
    }
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
