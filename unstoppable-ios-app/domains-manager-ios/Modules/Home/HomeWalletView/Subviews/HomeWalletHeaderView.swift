//
//  HomeWalletHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletHeaderView: View {
    
    let wallet: WalletEntity
    let domainNamePressedCallback: EmptyCallback
    @State private var domainAvatar: UIImage?
    @State private var rrDomainName: String?
    
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
            
            Text(formatCartPrice(wallet.totalBalance))
                .titleText()
        }
        .frame(maxWidth: .infinity)
        .onChange(of: wallet, perform: { wallet in
            loadAvatarIfNeeded(wallet: wallet)
        })
        .onAppear(perform: onAppear)
    }
    
}

// MARK: - Private methods
private extension HomeWalletHeaderView {
    func onAppear() {
        loadAvatarIfNeeded(wallet: wallet)
    }
    
    func loadAvatarIfNeeded(wallet: WalletEntity) {
        Task {
            if rrDomainName != wallet.rrDomain?.name {
                self.domainAvatar = nil
                if let domain = wallet.rrDomain,
                   let image = await appContext.imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: .mid) {
                    self.domainAvatar = image
                }
            }
        }
    }
    
    func getCurrentTitle() -> String {
        if let rrDomain = wallet.rrDomain {
            return rrDomain.name
        }
        return wallet.displayName
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
                         domainNamePressedCallback: { })
}
