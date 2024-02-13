//
//  ShareWalletInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.02.2024.
//

import SwiftUI
import TipKit

struct ShareWalletInfoView: View, ViewAnalyticsLogger {
        
    @Environment(\.imageLoadingService) var imageLoadingService
    
    let wallet: WalletEntity
    
    @State private var domainAvatarImage: UIImage?
    @State private var qrImage: UIImage?
    @State private var showingHint = false
    var analyticsName: Analytics.ViewName { .shareWalletInfo }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DismissIndicatorView(color: .white.opacity(0.16))
                qrImageView()
                walletDetailsView()
                Spacer()
                warningMessageView()
            }
            .onAppear(perform: onAppear)
            .padding(EdgeInsets(top: 30, leading: 16, bottom: 0, trailing: 16))
            .task {
                if #available(iOS 17.0, *) {
                    try? Tips.configure(
                        [.displayFrequency(.immediate),
                         .datastoreLocation(.applicationDefault)])
                }
                showingHint = true
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    if wallet.rrDomain == nil {
                        shareButtonView()
                    } else {
                        HStack {
                            copyAddressLargeButtonView()
                            shareButtonView()
                        }
                    }
                }
            }
        }
        .trackAppearanceAnalytics(analyticsLogger: self)
    }
}

// MARK: - Private methods
private extension ShareWalletInfoView {
    func onAppear() {
        loadDomainPFPAndQR()
    }
    
    func loadDomainPFPAndQR() {
        if let domain = wallet.rrDomain {
            Task.detached(priority: .high) {
                domainAvatarImage = await appContext.imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: nil)
            }
        }
        Task.detached(priority: .high) {
            if let url = URL(string: wallet.ethFullAddress),
               let image = await appContext.imageLoadingService.loadImage(from: .qrCode(url: url,
                                                                                              options: [.withLogo]),
                                                                                downsampleDescription: nil) {
                self.qrImage = image
            }
        }
    }
}

// MARK: - Views
private extension ShareWalletInfoView {
    @ViewBuilder
    func qrImageView() -> some View {
        ZStack {
            Image(uiImage: qrImage ?? .init())
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
            if qrImage == nil {
                ProgressView()
                    .tint(.black)
            }
        }
    }
    
    @ViewBuilder
    func nameView(_ name: String) -> some View {
        Text(name)
            .font(.currentFont(size: 22, weight: .bold))
            .foregroundStyle(Color.white)
            .lineLimit(1)
    }
    
    @ViewBuilder
    func walletDetailsView() -> some View {
        HStack(spacing: 12) {
            if let rrDomain = wallet.rrDomain {
                HStack(spacing: 12) {
                    copyDomainNameButtonWithTipView(domain: rrDomain)
                    nameView(rrDomain.name)
                    Spacer()
                    Image(uiImage: domainAvatarImage ?? .domainSharePlaceholder)
                        .resizable()
                        .squareFrame(24)
                        .clipShape(Circle())
                }
            } else {
                if wallet.displayInfo.isNameSet {
                    nameView(wallet.displayName)
                }
                Spacer()
                Button {
                    logButtonPressedAnalyticEvents(button: .copyToClipboard)
                    UDVibration.buttonTap.vibrate()
                    CopyWalletAddressPullUpHandler.copyToClipboard(address: wallet.address, ticker: "ETH")
                } label: {
                    HStack(spacing: 8) {
                        Text(wallet.address.walletAddressTruncated)
                            .font(.currentFont(size: 16, weight: .medium))
                        Image.copyToClipboardIcon
                            .resizable()
                            .squareFrame(20)
                    }
                    .foregroundStyle(Color.white.opacity(0.48))
                }
            }
            
        }
    }
    
    @ViewBuilder
    func warningMessageView() -> some View {
        Text(String.Constants.shareWalletAddressInfoMessage.localized())
            .font(.currentFont(size: 13))
            .multilineTextAlignment(.center)
            .foregroundColor(Color.white.opacity(0.32))
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))
            .frame(maxWidth: .infinity, alignment: .top)
    }
    
    @ViewBuilder
    func shareButtonView() -> some View {
        UDButtonView(text: String.Constants.shareAddress.localized(),
                     icon: wallet.rrDomain != nil ? nil : .shareFlatIcon,
                     style: .large(.raisedPrimary)) {
            logButtonPressedAnalyticEvents(button: .share)
            shareItems([wallet.ethFullAddress]) { success in
                logAnalytic(event: .shareResult,
                            parameters: [.success: String(success)])
            }
        }
    }
    
    @ViewBuilder
    func copyAddressLargeButtonView() -> some View {
        UDButtonView(text: String.Constants.copyAddress.localized(),
                     style: .large(.raisedTertiaryWhite)) {
            logButtonPressedAnalyticEvents(button: .copyToClipboard)
            UDVibration.buttonTap.vibrate()
            CopyWalletAddressPullUpHandler.copyToClipboard(address: wallet.address, ticker: "ETH")
        }
    }
    
    @ViewBuilder
    func copyDomainNameButtonWithTipView(domain: DomainDisplayInfo) -> some View {
        if #available(iOS 17.0, *) {
            copyDomainNameButtonView(domain: domain)
                .popoverTip(UseDomainNameTip())
        } else {
            copyDomainNameButtonView(domain: domain)
        }
    }
    
    @ViewBuilder
    func copyDomainNameButtonView(domain: DomainDisplayInfo) -> some View {
        UDIconButtonView(icon: .squareBehindSquareIcon,
                         style: .circle(size: .small,
                                        style: .raisedTertiaryWhite),
                         callback: {
            logButtonPressedAnalyticEvents(button: .copyToClipboard)
            UDVibration.buttonTap.vibrate()
            UIPasteboard.general.string = domain.name
            appContext.toastMessageService.showToast(.domainCopied, isSticky: false)
            showingHint.toggle()
        })
    }
    
    struct UseDomainNameTip: Tip {
        let id: String = "tip"
        let title: Text = Text("Use your domain name instead of long wallet address in the supported apps")
    }
}

#Preview {
    ShareWalletInfoView(wallet: MockEntitiesFabric.Wallet.mockEntities()[0])
}
