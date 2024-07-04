//
//  TransactionDetailsPullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.07.2024.
//

import SwiftUI

struct TransactionDetailsPullUpView: View {
    
    @Environment(\.imageLoadingService) var imageLoadingService

    let tx: WalletTransactionDisplayInfo
    
    @State private var fromDomainIcon: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            DismissIndicatorView()
                .padding(.vertical, 16)
            titleViews()
            txVisualisationsView()
                .padding(.top, 24)
            ZStack {
                curveLine()
                infoSectionsView()
            }
            viewTxButton()
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color.backgroundDefault)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension TransactionDetailsPullUpView {
    func onAppear() {
        loadFromInfoDomainIcon()
    }
    
    func loadFromInfoDomainIcon() {
        Task {
            if let domainName = tx.from.domainName {
                fromDomainIcon = await imageLoadingService.loadImage(from: .domainNameInitials(domainName,
                                                                                               size: .default),
                                                                     downsampleDescription: .mid)
                
                if let pfp = await imageLoadingService.loadImage(from: .walletDomain(tx.from.address),
                                                                 downsampleDescription: .mid) {
                    fromDomainIcon = pfp
                }
            }
        }
    }
    
    @ViewBuilder
    func titleViews() -> some View {
        VStack(spacing: 8) {
            Text(title)
                .textAttributes(color: .foregroundDefault, fontSize: 22, fontWeight: .bold)
            HStack {
                Text(tx.time, style: .date)
                Text("·")
                Text(tx.time, style: .time)
            }
            .textAttributes(color: .foregroundSecondary, fontSize: 16)
        }
    }
    
    var title: String {
        switch tx.type {
        case .tokenDeposit, .nftDeposit:
            String.Constants.receivedSuccessfully.localized()
        case .tokenWithdrawal, .nftWithdrawal:
            String.Constants.sentSuccessfully.localized()
        }
    }
    
    @ViewBuilder
    func txVisualisationsView() -> some View {
        ZStack {
            HStack(spacing: 8) {
                TxItemVisualisationView(tx: tx)
                TxReceiverVisualisationView(tx: tx)
            }
            ConnectTransactionSign()
                .rotationEffect(.degrees(-90))
        }
        .frame(height: 136)
    }
    
    @MainActor
    @ViewBuilder
    func curveLine() -> some View {
        ConnectDarkCurveLine(numberOfSections: getCurrentSections().count + 1)
    }
    
    @MainActor
    @ViewBuilder
    func infoSectionsView() -> some View {
        VStack(spacing: 0) {
            ForEach(getCurrentSections(), id: \.self) { section in
                ConnectLineSectionView(section: section)
                    .frame(height: ConnectCurveLine.sectionHeight)
            }
        }
        .padding(.init(horizontal: 16))
    }
    
    var fromInfoIcon: UIImage {
        if let fromDomainIcon {
            return fromDomainIcon
        }
        return .walletExternalIcon
    }
    
    func getCurrentSections() -> [ConnectLineSectionView.SectionType] {
        [.infoValue(.init(title: String.Constants.from.localized(),
                          icon: fromInfoIcon,
                          value: tx.from.displayName)),
         .infoValue(.init(title: String.Constants.chain.localized(),
                          icon: tx.chainIcon,
                          value: tx.chainFullName)),
         .infoValue(.init(title: String.Constants.networkFee.localized(),
                          icon: .gas,
                          value: tx.gas.formatted(toMaxNumberAfterComa: 4)))]
    }
    
    @ViewBuilder
    func viewTxButton() -> some View {
        if let url = tx.link {
            UDButtonView(text: String.Constants.viewTransaction.localized(),
                         style: .large(.raisedPrimary)) {
                appContext.analyticsService.log(event: .buttonPressed,
                                                withParameters: [.pullUpName: Analytics.PullUp.transactionDetails.rawValue,
                                                                 .button: Analytics.Button.viewTransaction.rawValue])
                openURL(url)
            }
        }
    }
    
    @MainActor
    func openURL(_ url: URL) {
        openLink(.direct(url: url))
    }
    
    var canViewTransaction: Bool {
        tx.link != nil
    }
}

// MARK: - Private methods
private extension TransactionDetailsPullUpView {
    struct TxItemVisualisationView: View {
        
        @Environment(\.imageLoadingService) var imageLoadingService

        let tx: WalletTransactionDisplayInfo
        @State private var icon: UIImage?

        var body: some View {
            BaseVisualisationView(title: title,
                                  subtitle: subtitle,
                                  backgroundStyle: .plain) {
                switch tx.type {
                case .tokenDeposit, .tokenWithdrawal:
                    iconView()
                        .clipShape(Circle())
                case .nftDeposit, .nftWithdrawal:
                    iconView()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .onAppear(perform: onAppear)
        }
        
        var title: String {
            switch tx.type {
            case .tokenDeposit, .tokenWithdrawal:
                BalanceStringFormatter.tokensBalanceUSDString(tx.value)
            case .nftDeposit, .nftWithdrawal:
                tx.nftName
            }
        }
        
        var subtitle: String {
            switch tx.type {
            case .tokenDeposit, .tokenWithdrawal:
                "\(tx.value.formatted(toMaxNumberAfterComa: 4)) \(tx.symbol)"
            case .nftDeposit, .nftWithdrawal:
                if tx.isDomainNFT {
                    String.Constants.domain.localized()
                } else {
                    String.Constants.collectible.localized()
                }
            }
        }
        
        var itemIcon: UIImage {
            icon ?? .init()
        }
        
        @ViewBuilder
        private func iconView() -> some View {
            UIImageBridgeView(image: itemIcon)
        }
        
        private func onAppear() {
            loadIcon()
        }
        
        private func loadIcon() {
            Task {
                if let url = tx.imageUrl {
                    icon = await imageLoadingService.loadImage(from: .url(url, maxSize: nil),
                                                               downsampleDescription: .mid)
                }
            }
        }
    }
    
    struct TxReceiverVisualisationView: View {
        
        @Environment(\.imageLoadingService) var imageLoadingService
        @Environment(\.domainProfilesService) var domainProfilesService
        
        let tx: WalletTransactionDisplayInfo
        @State private var icon: UIImage?
        @State private var profile: DomainProfileDisplayInfo?
        
        var body: some View {
            BaseVisualisationView(title: title,
                                  subtitle: subtitle,
                                  backgroundStyle: .active(.success)) {
                switch tx.type {
                case .tokenDeposit, .tokenWithdrawal:
                    iconView()
                        .clipShape(Circle())
                case .nftDeposit, .nftWithdrawal:
                    iconView()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
                                  .onAppear(perform: onAppear)
                                  .animation(.default, value: UUID())
        }
        
        var title: String {
            if let receiverDomainName {
                return receiverDomainName
            }
            return tx.to.address.walletAddressTruncated
        }
        
        var subtitle: String {
            if receiverDomainName == nil {
                return String.Constants.recipient.localized()
            }
            return tx.to.address.walletAddressTruncated
        }
        
        @ViewBuilder
        private func iconView() -> some View {
            if let icon {
                UIImageBridgeView(image: icon)
            } else {
                Image.walletExternalIcon
                    .resizable()
                    .padding(8)
                    .background(Color.backgroundMuted2)
            }
        }
        
        private func onAppear() {
            loadIcon()
        }
        
        private var receiverDomainName: String? {
            if let profile {
                return profile.domainName
            }
            return nil
        }
        
        private func loadIcon() {
            Task {
                if let profile = try? await domainProfilesService.fetchResolvedDomainProfileDisplayInfo(for: tx.to.address) {
                    self.profile = profile
                    icon = await imageLoadingService.loadImage(from: .domainNameInitials(profile.domainName,
                                                                                         size: .default),
                                                               downsampleDescription: .mid)
                    icon = await imageLoadingService.loadImage(from: .domainPFPSource(profile.pfpInfo.source),
                                                               downsampleDescription: .mid)
                }
               
            }
        }
    }

}

private struct BaseVisualisationView<C: View>: View {
    
    let title: String
    let subtitle: String
    let backgroundStyle: BackgroundStyle
    @ViewBuilder var iconContent: () -> C
    
    var body: some View {
        ZStack {
            if case .active = backgroundStyle {
                Image.confirmSendTokenGrid
                    .resizable()
            }
            VStack(spacing: 16) {
                iconContent()
                    .squareFrame(40)
                VStack(spacing: 0) {
                    Text(title)
                        .frame(height: 24)
                        .textAttributes(color: .foregroundDefault, fontSize: 20, fontWeight: .medium)
                    Text(subtitle)
                        .frame(height: 24)
                        .textAttributes(color: .foregroundSecondary, fontSize: 16)
                }
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        .background(backgroundView())
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(lineWidth: 1)
                .foregroundStyle(borderColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    var borderColor: Color {
        switch backgroundStyle {
        case .plain:
                .white.opacity(0.08)
        case .active(let activeBackgroundStyle):
            activeBackgroundStyle.borderColor
        }
    }
    
    @ViewBuilder
    func backgroundView() -> some View {
        switch backgroundStyle {
        case .plain:
            Color.backgroundOverlay
        case .active(let activeBackgroundStyle):
            activeBackgroundStyle.backgroundGradient
        }
    }
    
    enum BackgroundStyle {
        case plain
        case active(ActiveBackgroundStyle)
    }
    
    enum ActiveBackgroundStyle {
        case accent
        case success
        
        var borderColor: Color {
            switch self {
            case .accent:
                    .foregroundAccent
            case .success:
                    .foregroundSuccess
            }
        }
        
        var backgroundGradient: LinearGradient {
            switch self {
            case .accent:
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.05, green: 0.4, blue: 1).opacity(0), location: 0.25),
                        Gradient.Stop(color: Color(red: 0.05, green: 0.4, blue: 1).opacity(0.16), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5, y: 1)
                )
            case .success:
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.05, green: 0.65, blue: 0.4).opacity(0), location: 0.25),
                        Gradient.Stop(color: Color(red: 0.05, green: 0.65, blue: 0.4).opacity(0.16), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5, y: 1)
                )
            }
        }
    }
}

#Preview {
    TransactionDetailsPullUpView(tx: .init(serializedTransaction: MockEntitiesFabric.WalletTxs.createMockTxOf(type: .crypto, userWallet: "1", isDeposit: false), userWallet: "1"))
}
