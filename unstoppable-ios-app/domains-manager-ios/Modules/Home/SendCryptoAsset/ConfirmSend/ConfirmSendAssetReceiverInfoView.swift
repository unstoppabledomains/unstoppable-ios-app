//
//  ConfirmSendAssetReceiverInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

struct ConfirmSendAssetReceiverInfoView: View, ConfirmSendTokenViewsBuilderProtocol {
    
    @Environment(\.imageLoadingService) var imageLoadingService

    let receiver: SendCryptoAsset.AssetReceiver
    
    @State private var receiverAvatar: UIImage?

    var body: some View {
        receiverInfoView()
            .onAppear(perform: onAppear)

    }
}

// MARK: - Private methods
private extension ConfirmSendAssetReceiverInfoView {
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
private extension ConfirmSendAssetReceiverInfoView {
    @MainActor
    @ViewBuilder
    func receiverInfoView() -> some View {
        HStack(spacing: 16) {
            UIImageBridgeView(image: receiverAvatar ?? .domainSharePlaceholder)
                .squareFrame(40)
                .clipShape(Circle())
            receiverAddressInfoView()
            Spacer()
        }
        .padding(.init(horizontal: 16, vertical: SendCryptoAsset.Constants.tilesVerticalPadding))
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

#Preview {
    ConfirmSendAssetReceiverInfoView(receiver: MockEntitiesFabric.SendCrypto.mockReceiver())
}
