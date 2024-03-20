//
//  SelectCryptoAssetToSendDomainView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectCryptoAssetToSendDomainView: View {
    
    @Environment(\.imageLoadingService) var imageLoadingService

    let domain: DomainDisplayInfo
    
    @State private var avatar: UIImage?

    var body: some View {
        HStack(spacing: 16) {
            avatarImageView()
            VStack(alignment: .leading, spacing: 0) {
                domainNameView()
            }
            Spacer(minLength: 0)
            primaryIndicatorView()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Private methods
private extension SelectCryptoAssetToSendDomainView {
    func onAppear() {
        loadAvatar()
    }
    
    func loadAvatar() {
        Task {
            avatar = await imageLoadingService.loadImage(from: .domainItemOrInitials(domain,
                                                                                     size: .default),
                                                         downsampleDescription: .mid)
        }
    }
}

// MARK: - Private methods
private extension SelectCryptoAssetToSendDomainView {
    @ViewBuilder
    func avatarImageView() -> some View {
        UIImageBridgeView(image: avatar ?? .domainSharePlaceholder)
            .squareFrame(40)
            .clipShape(Circle())
    }
    
    @ViewBuilder
    func domainNameView() -> some View {
        Text(domain.name)
            .font(.currentFont(size: 16, weight: .medium))
            .foregroundStyle(Color.foregroundDefault)
            .lineLimit(1)
    }
    
    @ViewBuilder
    func primaryIndicatorView() -> some View {
        if domain.isSetForRR {
            HStack(spacing: 8) {
                Text(String.Constants.primary.localized())
                Image.crownIcon
                    .resizable()
                    .squareFrame(20)
            }
            .foregroundStyle(Color.foregroundDefault)
        }
    }
}

#Preview {
    SelectCryptoAssetToSendDomainView(domain: MockEntitiesFabric.Domains.mockDomainDisplayInfo())
}
