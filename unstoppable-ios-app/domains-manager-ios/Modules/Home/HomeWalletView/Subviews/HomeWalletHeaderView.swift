//
//  HomeWalletHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletHeaderView: View {
    
    let wallet: WalletEntity
    let totalBalance: Int
    let domainNamePressedCallback: EmptyCallback
    @State private var domainAvatar: UIImage?
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            getAvatarView()
                .squareFrame(80)
                .clipShape(Circle())
                .shadow(color: Color.backgroundDefault, radius: 24, x: 0, y: 0)
                .overlay {
                    Circle()
                        .stroke(lineWidth: 2)
                        .foregroundStyle(Color.backgroundDefault)
                }
            
            Button {
                UDVibration.buttonTap.vibrate()
                domainNamePressedCallback()
            } label: {
                HStack(spacing: 0) {
                    Text(getCurrentTitle())
                        .font(.currentFont(size: 16, weight: .medium))
                    Image.chevronGrabberVertical
                        .squareFrame(24)
                }
                .foregroundStyle(Color.foregroundSecondary)
            }
            .buttonStyle(.plain)
            
            Text(formatCartPrice(totalBalance))
                .titleText()
        }
        .frame(maxWidth: .infinity)
        .onAppear(perform: loadAvatarIfNeeded)
    }
    
}

// MARK: - Private methods
private extension HomeWalletHeaderView {
    func getCurrentTitle() -> String {
        if let rrDomain = wallet.rrDomain {
            return rrDomain.name
        }
        return wallet.displayName
    }
    
    func loadAvatarIfNeeded() {
        Task {
            if domainAvatar == nil,
               let domain = wallet.rrDomain,
               let image = await appContext.imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: .mid) {
                self.domainAvatar = image
            }
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
        Image(uiImage: domainAvatar ?? .domainSharePlaceholder)
            .resizable()
            .background(Color.clear)
    }
    
    @ViewBuilder
    func getAvatarViewToGetDomain() -> some View {
        Button {
            
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
}

#Preview {
    HomeWalletHeaderView(wallet: WalletEntity.mock().first!,
                         totalBalance: 20000,
                         domainNamePressedCallback: { })
}
