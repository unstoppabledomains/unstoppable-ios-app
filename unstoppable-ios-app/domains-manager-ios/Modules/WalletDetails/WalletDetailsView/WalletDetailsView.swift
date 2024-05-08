//
//  WalletDetailsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.05.2024.
//

import SwiftUI

struct WalletDetailsView: View {
    
    @Environment(\.walletsDataService) private var walletsDataService
    @Environment(\.dismiss) var dismiss

    @State var wallet: WalletEntity
    
    var body: some View {
        List {
            headerView()
                .padding(.bottom, 32)
                .listRowInsets(EdgeInsets(0))
            HomeWalletActionsView(actions: walletActions(),
                                  actionCallback: { action in
//                viewModel.walletActionPressed(action)
            }, subActionCallback: { subAction in
//                viewModel.walletSubActionPressed(subAction)
            })
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(0))

            HomeExploreSeparatorView()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(0))
                .padding(.vertical, 24)
            
            domainsListView()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }.environment(\.defaultMinListRowHeight, 28)
        .listRowSpacing(0)
        .background(Color.backgroundDefault)
        .onReceive(walletsDataService.walletsPublisher.receive(on: DispatchQueue.main)) { wallets in
            if let wallet = wallets.findWithAddress(wallet.address) {
                self.wallet = wallet
            } else {
                dismiss()
            }
        }
    }
    
}

// MARK: - Header
private extension WalletDetailsView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 24) {
            headerIcon()
            VStack(spacing: 16) {
                nameTextView()
                copyAddressButton()
            }
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    var isCenteredImage: Bool {
        switch wallet.displayInfo.source {
        case .locallyGenerated, .external:
            return false
        case .imported, .mpc:
            return true
        }
    }
    
    @ViewBuilder
    func headerIcon() -> some View {
        Image(uiImage: wallet.displayInfo.source.displayIcon)
            .resizable()
            .squareFrame(isCenteredImage ? 40 : 80)
            .padding(isCenteredImage ? 20 : 0)
            .background(Color.backgroundMuted2)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
    }
    
    @ViewBuilder
    func nameTextView() -> some View {
        Text(wallet.displayName)
            .titleText()
    }
    
    var copyButtonTitle: String {
        if wallet.displayInfo.isNameSet {
            wallet.address.walletAddressTruncated
        } else {
            String.Constants.copyAddress.localized()
        }
    }
    
    @ViewBuilder
    func copyAddressButton() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
        } label: {
            HStack(spacing: 8) {
                Text(copyButtonTitle)
                    .font(.currentFont(size: 16, weight: .medium))
                Image.copyToClipboardIcon
                    .resizable()
                    .squareFrame(20)
            }
            .foregroundStyle(Color.foregroundSecondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Actions
private extension WalletDetailsView {
    func walletActions() -> [WalletDetails.WalletAction] {
        var actions: [WalletDetails.WalletAction] = [.rename]
        
        if wallet.displayInfo.source.canBeBackedUp {
            actions.append(.backUp(wallet.displayInfo.backupState))
        }
        actions.append(.more)
        
        return actions
    }
}

// MARK: - Domains list
private extension WalletDetailsView {
    @ViewBuilder
    func domainsListView() -> some View {
        if wallet.domains.isEmpty {
            noDomainsView()
        } else {
            domainsListSection()
        }
    }
    
    @ViewBuilder
    func noDomainsView() -> some View {
        Text("No domains")
            .foregroundStyle(Color.foregroundSecondary)
            .font(.currentFont(size: 20, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 300)
    }
    
    var nonRRDomains: [DomainDisplayInfo] {
        wallet.domains.filter({ !$0.isSetForRR })
    }
    
    @ViewBuilder
    func domainsListSection() -> some View {
        domainsSectionHeaderView()
        if let rrDomain = wallet.rrDomain {
            domainSectionView {
                listViewFor(domain: rrDomain)
            }
        }
        if !nonRRDomains.isEmpty {
            domainSectionView {
                ForEach(nonRRDomains) { domain in
                    listViewFor(domain: domain)
                }
            }
        }
    }
    
    @ViewBuilder
    func domainSectionView(@ViewBuilder content: @escaping () -> some View) -> some View {
        Section {
            content()
        }
        .listRowBackground(Color.backgroundOverlay)
        .listRowSeparator(.hidden)
        .sectionSpacing(16)
    }
    
    
    @ViewBuilder
    func domainsSectionHeaderView() -> some View {
        HStack(spacing: 8) {
            Text(String.Constants.domains.localized())
                .foregroundStyle(Color.foregroundDefault)
            Text(String(wallet.domains.count))
                .foregroundStyle(Color.foregroundSecondary)
            Spacer()
        }
        .font(.currentFont(size: 20, weight: .bold))
        .listRowInsets(EdgeInsets(4))
    }
    
    @ViewBuilder
    func listViewFor(domain: DomainDisplayInfo) -> some View {
        WalletDetailsDomainItemView(domain: domain)
            .udListItemInCollectionButtonPadding()
            .listRowInsets(EdgeInsets(4))
    }
}

#Preview {
    WalletDetailsView(wallet: MockEntitiesFabric.Wallet.mockEntities()[0])
}


enum WalletDetails {
    
    enum WalletAction: HomeWalletActionItem {
        
        var id: String {
            switch self {
            case .rename:
                return "send"
            case .backUp:
                return "buy"
            case .more:
                return "more"
            }
        }
        
        case rename
        case backUp(WalletDisplayInfo.BackupState)
        case more
        
        var title: String {
            switch self {
            case .rename:
                return String.Constants.rename.localized()
            case .backUp(let state):
                if case .backedUp = state {
                    return String.Constants.backedUp.localized()
                }
                return String.Constants.backUp.localized()
            case .more:
                return String.Constants.more.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .rename:
                return .brushSparkle
            case .backUp(let state):
                if case .backedUp = state {
                    return Image(uiImage: state.icon)
                }
                return .cloudIcon
            case .more:
                return .dotsIcon
            }
        }
        
        var tint: Color {
            switch self {
            case .backUp(let state):
                if case .backedUp = state {
                    return .foregroundSuccess
                }
                return .foregroundAccent
            default:
                return .foregroundAccent
            }
        }
        
        var subActions: [WalletSubAction] {
            switch self {
            case .backUp, .rename:
                return []
            case .more:
                return WalletSubAction.allCases
            }
        }
        
        var analyticButton: Analytics.Button {
            switch self {
            case .rename:
                return .walletRename
            case .backUp:
                return .walletBackup
            case .more:
                return .more
            }
        }
        
        var isDimmed: Bool {
            switch self {
            case .rename, .backUp, .more:
                return false
            }
        }
    }
    
    enum WalletSubAction: String, CaseIterable, HomeWalletSubActionItem {
        
        case copyWalletAddress
        case connectedApps
        case buyMPC
        
        var title: String {
            switch self {
            case .copyWalletAddress:
                return String.Constants.copyWalletAddress.localized()
            case .connectedApps:
                return String.Constants.connectedAppsTitle.localized()
            case .buyMPC:
                return "Buy MPC"
            }
        }
        
        var icon: Image {
            switch self {
            case .copyWalletAddress:
                return Image.systemDocOnDoc
            case .connectedApps:
                return Image.systemAppBadgeCheckmark
            case .buyMPC:
                return .wallet3Icon
            }
        }
        
        var analyticButton: Analytics.Button {
            switch self {
            case .copyWalletAddress:
                return .copyWalletAddress
            case .connectedApps:
                return .connectedApps
            case .buyMPC:
                return .unblock
            }
        }
    }
    
}
