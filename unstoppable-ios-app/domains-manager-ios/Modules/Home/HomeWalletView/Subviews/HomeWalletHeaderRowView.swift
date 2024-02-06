//
//  HomeWalletHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletHeaderRowView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    @EnvironmentObject private var tabRouter: HomeTabRouter
    let wallet: WalletEntity
    let domainNamePressedCallback: MainActorCallback

    @State private var domainAvatar: UIImage?
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            avatarView()
            VStack(alignment: .center, spacing: 8) {
                profileSelectionView()
                totalBalanceView()
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: wallet, perform: { wallet in
            loadAvatarFor(wallet: wallet)
        })
        .onAppear(perform: onAppear)
    }
    
}

// MARK: - Private methods
private extension HomeWalletHeaderRowView {
    func onAppear() {
        loadAvatarFor(wallet: wallet)
    }
    
    func loadAvatarFor(wallet: WalletEntity) {
        Task {
            self.domainAvatar = nil
            if let domain = wallet.rrDomain,
               let image = await imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: .mid) {
                self.domainAvatar = image
            }
        }
    }
    
    @ViewBuilder
    func avatarView() -> some View {
        getAvatarView()
            .squareFrame(80)
            .clipShape(Circle())
            .shadow(color: Color.backgroundDefault, radius: 24, x: 0, y: 0)
            .overlay {
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundStyle(Color.backgroundDefault)
            }
    }
    
    @ViewBuilder
    func getAvatarView() -> some View {
        if let domain = wallet.rrDomain {
            getAvatarViewForDomain(domain)
        } else {
            getAvatarViewToGetDomain()
        }
    }
    
    @ViewBuilder
    func getAvatarViewForDomain(_ domain: DomainDisplayInfo) -> some View {
        UIImageBridgeView(image: domainAvatar ?? .domainSharePlaceholder,
                          width: 20,
                          height: 20)
    }
    
    @ViewBuilder
    func getAvatarViewToGetDomain() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            tabRouter.runPurchaseFlow()
        } label: {
            ZStack {
                Circle()
                    .foregroundStyle(Color.backgroundWarning)
                VStack(spacing: 4) {
                    Image.plusIconNav
                        .resizable()
                        .squareFrame(20)
                    Text(String.Constants.domain.localized())
                        .font(.currentFont(size: 13, weight: .medium))
                        .frame(height: 20)
                }
                .foregroundStyle(Color.foregroundWarning)
            }
            
        }
        .buttonStyle(.plain)
    }
    
    func getProfileSelectionTitle() -> String {
        if let rrDomain = wallet.rrDomain {
            return rrDomain.name
        }
        return wallet.displayName
    }
    
    @ViewBuilder
    func profileSelectionView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            domainNamePressedCallback()
        } label: {
            HStack(spacing: 0) {
                Text(getProfileSelectionTitle())
                    .font(.currentFont(size: 16, weight: .medium))
                Image.chevronGrabberVertical
                    .squareFrame(24)
            }
            .foregroundStyle(Color.foregroundSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func totalBalanceView() -> some View {
        Text("$\(wallet.totalBalance.formatted(toMaxNumberAfterComa: 2))")
            .titleText()
    }
}

#Preview {
    HomeWalletHeaderRowView(wallet: MockEntitiesFabric.Wallet.mockEntities().first!, 
                            domainNamePressedCallback: { })
}
