//
//  ChatListNavTitleView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct HomeProfileSelectorNavTitleView: View {
    @Environment(\.userProfilesService) private var userProfilesService
    @Environment(\.imageLoadingService) private var imageLoadingService
    @EnvironmentObject var tabRouter: HomeTabRouter

    var shouldHideAvatar: Bool = false
    @State var profile: UserProfile?
    @State private var avatar: UIImage?
    
    
    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            tabRouter.isSelectProfilePresented = true
        } label: {
            ZStack {
                Rectangle()
                    .frame(width: 200, 
                           height: 30)
                    .opacity(0.001)
                    .layoutPriority(-1)
                HStack(spacing: 8) {
                    content()
                    if isSelectable {
                        Image.chevronGrabberVertical
                            .resizable()
                            .squareFrame(20)
                            .foregroundStyle(Color.foregroundDefault)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isSelectable)
            .frame(maxWidth: 200)
            .onAppear(perform: loadAvatar)
            .onReceive(userProfilesService.selectedProfilePublisher.receive(on: DispatchQueue.main), perform: { selectedProfile in
                if let selectedProfile {
                    avatar = nil
                    loadAvatar()
                    self.profile = selectedProfile
                }
            })
    }
}

// MARK: - Private methods
private extension HomeProfileSelectorNavTitleView {
    var isSelectable: Bool {
        true
    }
    
    @ViewBuilder
    func content() -> some View {
        switch profile {
        case .wallet(let wallet):
            contentForWallet(wallet)
        case .webAccount(let user):
            contentForUser(user)
        case .none:
            Text("")
        }
    }
    
    func loadAvatar() {
        Task {
            if case .wallet(let wallet) = profile,
               let rrDomain = wallet.rrDomain {
                avatar =  await imageLoadingService.loadImage(from: .domain(rrDomain), downsampleDescription: .mid)
            }
        }
    }
    
    @ViewBuilder
    func contentForUser(_ user: FirebaseUser) -> some View {
        HStack(spacing: 8) {
            if !shouldHideAvatar {
                headerIconView(size: 12)
                    .squareFrame(20)
            }
            Text(user.displayName)
                .font(.currentFont(size: 16, weight: .semibold))
                .foregroundStyle(Color.foregroundDefault)
                .lineLimit(1)
                .frame(height: 20)
        }
    }
    
    @ViewBuilder
    func headerIconView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .foregroundStyle(Color.backgroundSuccessEmphasis)
            Image.globeIcon
                .resizable()
                .squareFrame(size)
                .foregroundStyle(Color.foregroundOnEmphasis)
        }
    }
    
    @ViewBuilder
    func contentForWallet(_ wallet: WalletEntity) -> some View {
        if let rrDomain = wallet.rrDomain {
            HStack(spacing: 8) {
                if !shouldHideAvatar {
                    UIImageBridgeView(image: avatar ?? .domainSharePlaceholder)
                        .squareFrame(20)
                        .clipShape(Circle())
                }
                Text(rrDomain.name)
                    .font(.currentFont(size: 16, weight: .semibold))
                    .foregroundStyle(Color.foregroundDefault)
                    .lineLimit(1)
            }
            .frame(height: 20)
        } else {
            Text(wallet.displayName)
                .font(.currentFont(size: 16, weight: .semibold))
                .foregroundStyle(Color.foregroundDefault)
                .lineLimit(1)
                .frame(height: 20)
        }
    }
}

// MARK: - Open methods
extension HomeProfileSelectorNavTitleView {
    
}

#Preview {
    HomeProfileSelectorNavTitleView(profile: appContext.userProfilesService.selectedProfile!)
}
