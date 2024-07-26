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
    @State private var tokenImage: UIImage?
    @State private var qrImage: UIImage?
    @State private var showingHint = false
    
    var body: some View {
        VStack(spacing: 0) {
            contentViewsForWalletAssetType()
        }
        .onAppear(perform: onAppear)
        .padding(.horizontal, 16)
        .passViewAnalyticsDetails(logger: self)
        .trackAppearanceAnalytics(analyticsLogger: self)
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
            token.loadTokenIcon { image in
                tokenImage = image
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
                .padding(.top, 30)
            contentViewForSingleChainWallet(token: token)
        case .multiChain(let tokens, let callback):
            contentViewForMultiChainWallet(tokens: tokens, callback: callback)
                .padding(.top, 30)
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
            logButtonPressedAnalyticEvents(button: .copyDomain)
            UDVibration.buttonTap.vibrate()
            copyDomainName(domain.name)
            showingHint.toggle()
        })
    }
    
    @MainActor
    func copyDomainName(_ domainName: String) {
        UIPasteboard.general.string = domainName
        appContext.toastMessageService.showToast(.domainCopied, isSticky: false)
    }
    
    struct UseDomainNameTip: Tip {
        let id: String = "tip"
        let title: Text = Text(String.Constants.useDomainNameInsteadOfAddress.localized())
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
            VStack(spacing: 32) {
                multiChainContentHeader()
                HomeExploreSeparatorView()
                tokensListSection(tokens: filterMultiChainTokensToDisplay(tokens: tokens),
                                  callback: callback)
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }
    
    func filterMultiChainTokensToDisplay(tokens: [BalanceTokenUIDescription]) -> [BalanceTokenUIDescription] {
        tokens
    }
    
    @ViewBuilder
    func multiChainContentHeader() -> some View {
        if let rrDomain {
            VStack(spacing: 20) {
                Image(uiImage: domainAvatarImage ?? .domainSharePlaceholder)
                    .resizable()
                    .squareFrame(80)
                    .clipShape(Circle())
                VStack(spacing: 16) {
                    multiChainCopyDomainNameHeader(domainName: rrDomain.name)
                    Text(String.Constants.useDomainNameInsteadOfAddress.localized())
                        .textAttributes(color: .foregroundSecondary, fontSize: 16)
                }
            }
        }
    }
    
    @ViewBuilder
    func multiChainCopyDomainNameHeader(domainName: String) -> some View {
        Button {
            logButtonPressedAnalyticEvents(button: .copyDomain)
            UDVibration.buttonTap.vibrate()
            Task {
                await copyDomainName(domainName)
            }
        } label: {
            HStack(spacing: 8) {
                Text(domainName)
                    .textAttributes(color: .foregroundDefault,
                                    fontSize: 32,
                                    fontWeight: .bold)
                    .lineLimit(1)
                Image.copyToClipboardIcon
                    .resizable()
                    .squareFrame(24)
                    .foregroundStyle(Color.foregroundSecondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func tokensListSection(tokens: [BalanceTokenUIDescription],
                           callback: @escaping @MainActor (BalanceTokenUIDescription)->()) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String.Constants.copyOrShareWalletAddress.localized())
                .foregroundStyle(Color.foregroundDefault)
                .font(.currentFont(size: 16, weight: .medium))
            UDCollectionSectionBackgroundView {
                VStack(alignment: .center, spacing: 0) {
                    ForEach(tokens, id: \.id) { token in
                        listViewFor(token: token, qrCodeCallback: {
                            callback(token)
                        })
                    }
                }
            }
            Text(String.Constants.mpcWalletShareMultiChainDescription.localizedMPCProduct())
                .foregroundStyle(Color.foregroundSecondary)
                .font(.currentFont(size: 14, weight: .medium))
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
        tokenHeaderView()
        qrImageView()
        walletDetailsView(token: token)
        Spacer()
    }
    
    @ViewBuilder
    func tokenHeaderView() -> some View {
        VStack(spacing: 20) {
            Image(uiImage: tokenImage ?? .init())
                .resizable()
                .squareFrame(80)
                .clipShape(Circle())
            Text(getTokenToShare()?.name ?? "")
                .textAttributes(color: .foregroundDefault,
                                fontSize: 32,
                                fontWeight: .bold)
        }
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
    ShareWalletAssetInfoView(asset: .multiChainAsset(MockEntitiesFabric.Tokens.mockEthToken()),
                             rrDomain: nil,
                             walletDisplayInfo: MockEntitiesFabric.Wallet.mockEntities()[0].displayInfo)
}
