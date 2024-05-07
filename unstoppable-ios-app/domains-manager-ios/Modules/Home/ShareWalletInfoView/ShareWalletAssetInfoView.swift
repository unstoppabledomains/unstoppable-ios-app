//
//  ShareTokenInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.05.2024.
//

import SwiftUI
import TipKit

struct ShareWalletAssetInfoView: View, ViewAnalyticsLogger {
    
    @Environment(\.imageLoadingService) var imageLoadingService
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    let asset: AssetsType
    let rrDomain: DomainDisplayInfo?
    let walletDisplayInfo: WalletDisplayInfo
    
    @State private var domainAvatarImage: UIImage?
    @State private var qrImage: UIImage?
    @State private var showingHint = false
    
    var body: some View {
        VStack(spacing: 0) {
            contentViewsForWalletAssetType()
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
            if let token = getTokenToShare() {
                ToolbarItem(placement: .bottomBar) {
                    if rrDomain == nil {
                        shareButtonView(token: token)
                    } else {
                        HStack {
                            copyAddressLargeButtonView(token: token)
                            shareButtonView(token: token)
                        }
                    }
                }
            }
        }
    }
    
}

// MARK: - Private methods
private extension ShareWalletAssetInfoView {
    func onAppear() {
        loadDomainPFPAndQR()
    }
    
    func loadDomainPFPAndQR() {
        if let domain = rrDomain {
            Task.detached(priority: .high) {
                domainAvatarImage = await appContext.imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: nil)
            }
        }
        if let token = getTokenToShare() {
            Task.detached(priority: .high) {
                if let url = URL(string: token.address),
                   let image = await appContext.imageLoadingService.loadImage(from: .qrCode(url: url,
                                                                                            options: [.withLogo]),
                                                                              downsampleDescription: nil) {
                    self.qrImage = image
                }
            }
        }
    }
    
    func getTokenToShare() -> BalanceTokenUIDescription? {
        switch asset {
        case .singleChain(let token), .multiChainAsset(let token):
            return token
        case .multiChain:
            return nil
        }
    }
}

// MARK: - Views
private extension ShareWalletAssetInfoView {
    @ViewBuilder
    func contentViewsForWalletAssetType() -> some View {
        switch asset {
        case .singleChain(let token):
            dismissIndicator()
            contentViewForSingleChainWallet(token: token)
        case .multiChain(let tokens, let callback):
            contentViewForMultiChainWallet(tokens: tokens, callback: callback)
        case .multiChainAsset(let token):
            contentViewForMultiChainAssetWallet(token: token)
        }
    }
 
    @ViewBuilder
    func dismissIndicator() -> some View {
        DismissIndicatorView(color: .white.opacity(0.16))
    }
    
    @ViewBuilder
    func shareButtonView(token: BalanceTokenUIDescription) -> some View {
        UDButtonView(text: String.Constants.shareAddress.localized(),
                     icon: rrDomain != nil ? nil : .shareFlatIcon,
                     style: .large(.raisedPrimary)) {
            logButtonPressedAnalyticEvents(button: .share)
            shareItems([token.address]) { success in
                logAnalytic(event: .shareResult,
                            parameters: [.success: String(success)])
            }
        }
    }
    
    @ViewBuilder
    func copyAddressLargeButtonView(token: BalanceTokenUIDescription) -> some View {
        UDButtonView(text: String.Constants.copyAddress.localized(),
                     style: .large(.raisedTertiaryWhite)) {
            logButtonPressedAnalyticEvents(button: .copyToClipboard)
            UDVibration.buttonTap.vibrate()
            CopyWalletAddressPullUpHandler.copyToClipboard(token: token)
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

// MARK: - Single chain
private extension ShareWalletAssetInfoView {
    @ViewBuilder
    func contentViewForSingleChainWallet(token: BalanceTokenUIDescription) -> some View {
        qrImageView()
        walletDetailsView(token: token)
        Spacer()
        warningMessageView()
    }
    
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
    func walletDetailsView(token: BalanceTokenUIDescription) -> some View {
        HStack(spacing: 12) {
            if let rrDomain {
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
                if walletDisplayInfo.isNameSet {
                    nameView(walletDisplayInfo.displayName)
                }
                Spacer()
                Button {
                    logButtonPressedAnalyticEvents(button: .copyToClipboard)
                    UDVibration.buttonTap.vibrate()
                    CopyWalletAddressPullUpHandler.copyToClipboard(token: token)
                } label: {
                    HStack(spacing: 8) {
                        Text(token.address.walletAddressTruncated)
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
}

// MARK: - Multi chain
private extension ShareWalletAssetInfoView {
    @ViewBuilder
    func contentViewForMultiChainWallet(tokens: [BalanceTokenUIDescription],
                                        callback: @escaping @MainActor (BalanceTokenUIDescription)->()) -> some View {
        ScrollView {
            tokensListSection(tokens: tokens,
                              callback: callback)
        }
    }
    
    @ViewBuilder
    func tokensListSection(tokens: [BalanceTokenUIDescription],
                           callback: @escaping @MainActor (BalanceTokenUIDescription)->()) -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(tokens, id: \.id) { token in
                    listViewFor(token: token, qrCodeCallback: {
                        callback(token)
                    })
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(token: BalanceTokenUIDescription,
                     qrCodeCallback: @escaping MainActorCallback) -> some View {
        CopyMultichainWalletAddressesPullUpView.TokenSelectionRowView(token: token,
                                                                      selectionType: .allOptions(qrCodeCallback: qrCodeCallback))
        .udListItemInCollectionButtonPadding()
        .padding(EdgeInsets(4))
    }
}

// MARK: - Multi chain token
private extension ShareWalletAssetInfoView {
    @ViewBuilder
    func contentViewForMultiChainAssetWallet(token: BalanceTokenUIDescription) -> some View {
        qrImageView()
        walletDetailsView(token: token)
        Spacer()
    }
}

// MARK: - Open methods
extension ShareWalletAssetInfoView {
    enum AssetsType: Hashable {
        
        case singleChain(BalanceTokenUIDescription)
        case multiChain(tokens: [BalanceTokenUIDescription], callback: @MainActor (BalanceTokenUIDescription)->())
        case multiChainAsset(BalanceTokenUIDescription)

        static func == (lhs: ShareWalletAssetInfoView.AssetsType, rhs: ShareWalletAssetInfoView.AssetsType) -> Bool {
            switch (lhs, rhs) {
            case (.singleChain(let lhsToken), .singleChain(let rhsToken)):
                return lhsToken == rhsToken
            case (.multiChain(let lhsTokens, _), .multiChain(let rhsTokens, _)):
                return lhsTokens == rhsTokens
            case (.multiChainAsset(let lhsToken), .multiChainAsset(let rhsToken)):
                return lhsToken == rhsToken
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .singleChain(let token), .multiChainAsset(let token):
                hasher.combine(token)
            case .multiChain(let tokens, _):
                hasher.combine(tokens)
            }
        }
    }
}

#Preview {
    ShareWalletAssetInfoView(asset: .singleChain(MockEntitiesFabric.Tokens.mockEthToken()),
                             rrDomain: nil,
                             walletDisplayInfo: MockEntitiesFabric.Wallet.mockEntities()[0].displayInfo)
}
