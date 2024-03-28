//
//  SendCryptoReceiverInfoTitleView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2024.
//

import SwiftUI

struct SendCryptoReceiverInfoTitleView: View {
    
    @Environment(\.imageLoadingService) var imageLoadingService
    @Environment(\.domainProfilesService) var domainProfilesService
    
    let receiver: SendCryptoAsset.AssetReceiver
    
    @State private var icon: UIImage?
    
    var body: some View {
        HStack(spacing: 8) {
            iconView()
            Text(receiver.walletAddress.walletAddressTruncated)
                .font(.currentFont(size: 16, weight: .semibold))
        }
        .animation(.default, value: UUID())
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension SendCryptoReceiverInfoTitleView {
    func onAppear() {
        loadIcon()
    }
    
    func loadIcon() {
        if let domainName = receiver.domainName,
           let profile = domainProfilesService.getCachedDomainProfileDisplayInfo(for: domainName),
           let pfpURL = profile.pfpURL {
            Task {
                icon = await imageLoadingService.loadImage(from: .url(pfpURL, maxSize: nil), downsampleDescription: .icon)
            }
        }
    }
    
    @ViewBuilder
    func iconView() -> some View {
        if let icon {
            UIImageBridgeView(image: icon)
                .squareFrame(20)
                .clipShape(Circle())
        }
    }
}

#Preview {
    SendCryptoReceiverInfoTitleView(receiver: .init(walletAddress: "0x1234567890abcdef1234567890abcdef12345678"))
}
