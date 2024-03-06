//
//  HomeExploreDomainRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct HomeExploreDomainRowView: View {
    
    @Environment(\.imageLoadingService) var imageLoadingService
    let domain: DomainDisplayInfo
    let selectionCallback: (DomainDisplayInfo)->()
    
    @State private var avatar: UIImage?
    
    var body: some View {
        clickableContentView()
            .padding(.init(vertical: 4))
            .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension HomeExploreDomainRowView {
    var followersForDomain: Int? { nil }
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
private extension HomeExploreDomainRowView {
    @ViewBuilder
    func clickableContentView() -> some View {
        UDCollectionListRowButton(content: {
            contentView()
                .udListItemInCollectionButtonPadding()
        }, callback: {
            UDVibration.buttonTap.vibrate()
            selectionCallback(domain)
        })
    }
    
    @ViewBuilder
    func contentView() -> some View {
        HStack(spacing: 16) {
            avatarImageView()
            VStack(alignment: .leading, spacing: 0) {
                domainNameView()
                followersInfoView()
            }
            Spacer(minLength: 0)
            primaryIndicatorView()
        }
        .frame(maxWidth: .infinity)
    }
    
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
    func followersInfoView() -> some View {
        if let followersForDomain {
            Text(String.Constants.pluralNFollowers.localized(followersForDomain, followersForDomain))
                .font(.currentFont(size: 14))
                .foregroundStyle(Color.foregroundSecondary)
        }
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
    HomeExploreDomainRowView(domain: MockEntitiesFabric.Domains.mockDomainDisplayInfo(),
                             selectionCallback: { _ in })
}
