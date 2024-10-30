//
//  WalletDetailsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.05.2024.
//

import SwiftUI

struct WalletDetailsView: View, ViewAnalyticsLogger {
    
    @Environment(\.walletsDataService) private var walletsDataService
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tabRouter: HomeTabRouter

    @State var wallet: WalletEntity
    let source: UDRouter.WalletDetailsSource
    
    @State private var isRenaming = false
    @State private var pullUp: ViewPullUpConfigurationType?
    @State private var disabling2FAMetadata: MPCWalletMetadataWrapper?
    
    var analyticsName: Analytics.ViewName { .walletDetails }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.wallet : wallet.address] }
    
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
        .viewPullUp($pullUp)
        .clearListBackground()
        .background(Color.backgroundDefault)
        .passViewAnalyticsDetails(logger: self)
        .trackAppearanceAnalytics(analyticsLogger: self)
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
        .sheet(item: $disabling2FAMetadata, content: { mpcMetadataWrapper in
            MPCSetup2FAConfirmCodeView(verificationPurpose: .disable(mpcMetadataWrapper.metadata),
                                       navigationStyle: .modal)
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
                underNameView()
            }
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    func underNameView() -> some View {
        HStack(spacing: 16) {
            externalWalletBadgeView()
            copyAddressButton()
        }
    }
    
    @ViewBuilder
    func externalWalletBadgeView() -> some View {
        if case .external = wallet.displayInfo.source {
            Button {
                UDVibration.buttonTap.vibrate()
                externalBadgePressed()
            } label: {
                HStack(spacing: 8) {
                    Image.externalWalletIndicator
                        .resizable()
                        .squareFrame(20)
                    Text(String.Constants.external.localized())
                        .font(.currentFont(size: 16, weight: .medium))
                }
                .foregroundStyle(Color.foregroundSecondary)
                .frame(height: 20)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.backgroundSubtle)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
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
            logButtonPressedAnalyticEvents(button: .copyWalletAddress)
            copyAddressButtonPressed()
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
    
    func externalBadgePressed() {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

        
        logButtonPressedAnalyticEvents(button: .showConnectedWalletInfo)
        appContext.pullUpViewService.showConnectedWalletInfoPullUp(in: view)
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
        
        if wallet.udWallet.type == .mpc,
           let mpcMetadata = wallet.udWallet.mpcMetadata {
            let is2FAEnabled = (try? mpcWalletsService.is2FAEnabled(for: mpcMetadata)) ?? false
            
            actions.append(.mpc2FA(is2FAEnabled))
            subActions.append(.mpcRecoveryKit)
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
        case .backUp(let state):
            let isNetworkReachable = appContext.networkReachabilityService?.isReachable == true
            guard isNetworkReachable else { return }
            
            switch state {
            case .backedUp:
                return
            case .importedNotBackedUp, .locallyGeneratedNotBackedUp:
                showBackupWalletScreenIfAvailable()
            }
        case .mpc2FA(let isEnabled):
            mpc2FAActionPressed(isEnabled)
        case .more:
            return
        }
    }
    
    func showBackupWalletScreenIfAvailable() {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

        guard iCloudWalletStorage.isICloudAvailable() else {
            view.showICloudDisabledAlert()
            return
        }
        
        UDRouter().showBackupWalletScreen(for: wallet.udWallet, walletBackedUpCallback: { _ in
            AppReviewService.shared.appReviewEventDidOccurs(event: .walletBackedUp)
        }, in: view)
    }
    
    func revealRecoveryPhrase(recoveryType: UDWallet.RecoveryType) {
        guard let view = appContext.coreAppCoordinator.topVC else { return }
        
        Task {
            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                UDRouter().showRecoveryPhrase(of: wallet.udWallet,
                                              recoveryType: recoveryType,
                                              in: view,
                                              dismissCallback: {
                    AppReviewService.shared.appReviewEventDidOccurs(event: .didRevealPK)
                })
            }
        }
    }
    
    func mpc2FAActionPressed(_ isEnabled: Bool) {
        if isEnabled {
            // TODO: - Use tabRouter.pullUp
            pullUp = .default(.mpc2FAEnabled(disableCallback: askToDisable2FA))
        } else {
            guard let mpcMetadata = wallet.udWallet.mpcMetadata else { return }
            
            tabRouter.walletViewNavPath.append(.mpcSetup2FAEnable(mpcMetadata: mpcMetadata))
        }
    }
    
    func askToDisable2FA() {
        pullUp = .default(.mpc2FADisableConfirmation(disableCallback: disable2FA))
    }
    
    func disable2FA() {
        guard let mpcMetadata = wallet.udWallet.mpcMetadata else { return }
        
        disabling2FAMetadata = .init(metadata: mpcMetadata)
    }
    
    func walletSubActionPressed(_ action: WalletDetails.WalletSubAction) {
        switch action {
        case .privateKey:
            revealRecoveryPhrase(recoveryType: .privateKey)
        case .recoveryPhrase:
            revealRecoveryPhrase(recoveryType: .recoveryPhrase)
        case .removeWallet, .disconnectWallet:
            askToRemoveWallet()
        case .mpcRecoveryKit:
            requestMPCWalletRecoveryKit()
        }
    }
    
    func askToRemoveWallet() {
        guard let view = appContext.coreAppCoordinator.topVC else { return }
        Task {
            do {
                try await appContext.pullUpViewService.showRemoveWalletPullUp(in: view, walletInfo: wallet.displayInfo)
                await view.dismissPullUpMenu()
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                await removeWallet()
            }
        }
    }
 
    func removeWallet() async {
        appContext.udWalletsService.remove(wallet: wallet.udWallet)
        // WC2 only
        await appContext.walletConnectServiceV2.disconnect(from: wallet.address)
        let wallets = appContext.udWalletsService.getUserWallets()
        guard !wallets.isEmpty else { return }
        indicateWalletRemoved()
    }
    
    func indicateWalletRemoved() {
        if wallet.udWallet.type == .externalLinked {
            appContext.toastMessageService.showToast(.walletDisconnected, isSticky: false)
        } else {
            appContext.toastMessageService.showToast(.walletRemoved(walletName: wallet.displayInfo.walletSourceName), isSticky: false)
        }
    }
    
    func requestMPCWalletRecoveryKit() {
        guard let mpcMetadata = wallet.udWallet.mpcMetadata else {
            Debugger.printFailure("Failed to get MPC metadata in wallet details for wallet: \(wallet.udWallet.address)",
                                  critical: true)
            return
        }
        
        tabRouter.requestingRecoveryMPC = MPCWalletMetadataDisplayInfo(walletMetadata: mpcMetadata)
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
        Text(String.Constants.noDomains.localized())
            .foregroundStyle(Color.foregroundSecondary)
            .font(.currentFont(size: 20, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 200)
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
        WalletDetailsDomainItemView(domain: domain,
                                    canSetRR: wallet.isReverseResolutionChangeAllowed(),
                                    selectionCallback: {
            didSelectDomain(domain)
        })
        .listRowInsets(EdgeInsets(0))
    }
    
    func didSelectDomain(_ domain: DomainDisplayInfo) {
        switch source {
        case .settings:
            Task {
                await tabRouter.showDomainProfile(domain,
                                                  wallet: wallet,
                                                  preRequestedAction: nil,
                                                  shouldResetNavigation: false,
                                                  sourceScreen: .domainsList)
            }
        case .domainDetails(let domainChangeCallback):
            domainChangeCallback(domain)
        }
    }
}

// MARK: - Private methods
private extension WalletDetailsView {
    struct MPCWalletMetadataWrapper: Identifiable {
        let id = UUID()
        let metadata: MPCWalletMetadata
    }
}

#Preview {
    let wallet = MockEntitiesFabric.Wallet.mockMPC()
    
    return WalletDetailsView(wallet: wallet,
                             source: .settings)
}
