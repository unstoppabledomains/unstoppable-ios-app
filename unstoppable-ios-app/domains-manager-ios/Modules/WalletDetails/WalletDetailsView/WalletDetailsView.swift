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
    @EnvironmentObject var tabRouter: HomeTabRouter

    @State var wallet: WalletEntity
    
    @State private var isRenaming = false
    
    var body: some View {
        List {
            headerView()
                .padding(.bottom, 32)
                .listRowInsets(EdgeInsets(0))
            HomeWalletActionsView(actions: walletActions(),
                                  actionCallback: { action in
                walletActionPressed(action)
            }, subActionCallback: { subAction in
                walletSubActionPressed(subAction)
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
        .sheet(isPresented: $isRenaming, content: {
            RenameWalletView(wallet: wallet)
        })
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
    
    @ViewBuilder
    func headerIcon() -> some View {
        WalletSourceImageView(displayInfo: wallet.displayInfo)
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
    
    func copyAddressButtonPressed() {
        switch wallet.getAssetsType() {
        case .multiChain(let tokens):
            tabRouter.pullUp = .custom(.copyMultichainAddressPullUp(tokens: tokens, selectionType: .copyOnly))
        case .singleChain(let token):
            CopyWalletAddressPullUpHandler.copyToClipboard(token: token)
        }
    }
}

// MARK: - Actions
private extension WalletDetailsView {
    func walletActions() -> [WalletDetails.WalletAction] {
        var actions: [WalletDetails.WalletAction] = [.rename]
        var subActions: [WalletDetails.WalletSubAction] = []
        
        if wallet.displayInfo.source.canBeBackedUp {
            actions.append(.backUp(wallet.displayInfo.backupState))
    
            if let recoveryType = UDWallet.RecoveryType(walletType: wallet.udWallet.type) {
                switch recoveryType {
                case .privateKey:
                    subActions.append(.privateKey)
                case .recoveryPhrase:
                    subActions.append(.recoveryPhrase)
                }
            }
        }
        
        if wallet.displayInfo.isConnected {
            subActions.append(.disconnectWallet)
        } else {
            subActions.append(.removeWallet)
        }
        
        actions.append(.more(subActions))
        
        return actions
    }
    
    func walletActionPressed(_ action: WalletDetails.WalletAction) {
        switch action {
        case .rename:
            isRenaming = true
        case .backUp, .more:
            return
        }
    }
    
    func walletSubActionPressed(_ action: WalletDetails.WalletSubAction) {
        
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
                return "backUp"
            case .more:
                return "more"
            }
        }
        
        case rename
        case backUp(WalletDisplayInfo.BackupState)
        case more([WalletSubAction])
        
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
            case .more(let subActions):
                return subActions
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
        
        case privateKey
        case recoveryPhrase
        case removeWallet
        case disconnectWallet
        
        var title: String {
            switch self {
            case .privateKey:
                return String.Constants.viewPrivateKey.localized()
            case .recoveryPhrase:
                return String.Constants.viewRecoveryPhrase.localized()
            case .removeWallet:
                return String.Constants.removeWallet.localized()
            case .disconnectWallet:
                return  String.Constants.disconnectWallet.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .recoveryPhrase, .privateKey:
                return Image.systemDocOnDoc
            case .removeWallet, .disconnectWallet:
                return Image.trashIcon
            }
        }
        
        var isDestructive: Bool {
            switch self {
            case .recoveryPhrase, .privateKey:
                return false
            case .removeWallet, .disconnectWallet:
                return true
            }
        }
        
        var analyticButton: Analytics.Button {
            switch self {
            case .recoveryPhrase, .privateKey:
                return .walletRecoveryPhrase
            case .removeWallet, .disconnectWallet:
                return .walletRemove
            }
        }
    }
    
}
