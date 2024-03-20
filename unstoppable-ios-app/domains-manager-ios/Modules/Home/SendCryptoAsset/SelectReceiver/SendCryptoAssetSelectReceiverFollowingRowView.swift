//
//  SendCryptoSelectReceiverFollowingRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SendCryptoAssetSelectReceiverFollowingRowView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService
    @Environment(\.domainProfilesService) private var domainProfilesService
    
    let domainName: DomainName
    @State private var profile: DomainProfileDisplayInfo?
    @State private var pfpImage: UIImage?
    
    var body: some View {
        contentView()
            .onAppear(perform: onAppear)
            .onChange(of: domainName) { newValue in
                loadProfileFor(domainName: newValue)
            }
    }
}

// MARK: - Private methods
private extension SendCryptoAssetSelectReceiverFollowingRowView {
    func onAppear() {
        loadProfileFor(domainName: domainName)
    }
    
    func loadProfileFor(domainName: String) {
        if let cachedProfile = domainProfilesService.getCachedDomainProfileDisplayInfo(for: domainName) {
            setProfile(cachedProfile)
        } else {
            setProfile(nil)
            Task {
                let profile = try await domainProfilesService.fetchDomainProfileDisplayInfo(for: domainName)
                setProfile(profile)
            }
        }
    }
    
    func setProfile(_ profile: DomainProfileDisplayInfo?) {
        self.profile = profile
        self.pfpImage = nil
        if let profile {
            loadAvatar(profile: profile)
        }
    }
    
    func loadAvatar(profile: DomainProfileDisplayInfo) {
        Task {
            if let url = profile.pfpURL {
                pfpImage = await imageLoadingService.loadImage(from: .url(url, maxSize: nil),
                                                               downsampleDescription: .mid)
            } else {
                pfpImage = await imageLoadingService.loadImage(from: .initials(domainName,
                                                                               size: .default,
                                                                               style: .accent), downsampleDescription: nil)
            }
        }
    }
}

// MARK: - Private methods
private extension SendCryptoAssetSelectReceiverFollowingRowView {
    @ViewBuilder
    func contentView() -> some View {
        HStack(spacing: 16) {
            pfpView()
            infoView()
            Spacer()
        }
    }
    
    @ViewBuilder
    func pfpView() -> some View {
        UIImageBridgeView(image: pfpImage ?? .domainSharePlaceholder)
            .squareFrame(40)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .inset(by: 0.5)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            }
    }
    
    @ViewBuilder
    func infoView() -> some View {
        VStack {
            Text(domainName)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
        }
        .lineLimit(1)
    }
}

#Preview {
    SendCryptoAssetSelectReceiverFollowingRowView(domainName: "oleg.x")
}
