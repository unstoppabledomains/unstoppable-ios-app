//
//  HomeWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.01.2024.
//

import SwiftUI

struct HomeWalletView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @EnvironmentObject var stateManagerWrapper: NavigationStateManagerWrapper
    @StateObject var viewModel: HomeWalletViewModel
    @StateObject private var profilesAPIFlagTracker = UDMaintenanceModeFeatureFlagTracker(featureFlag: .isMaintenanceProfilesAPIEnabled)
    @StateObject private var mpcFlagTracker = UDMaintenanceModeFeatureFlagTracker(featureFlag: .isMaintenanceMPCEnabled)
    @State private var isOtherScreenPresented: Bool = false
    private var navigationState: NavigationStateManager? { stateManagerWrapper.navigationState }
    var isOtherScreenPushed: Bool { !tabRouter.walletViewNavPath.isEmpty }
    
    var body: some View {
            List {
                HomeWalletHeaderRowView(wallet: viewModel.selectedWallet,
                                        actionCallback: viewModel.walletActionPressed,
                                        didSelectDomainCallback: viewModel.didSelectChangeRR,
                                        purchaseDomainCallback: viewModel.buyDomainPressed)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .unstoppableListRowInset()
                
                HomeWalletActionsView(actions: walletActions(),
                                      actionCallback: { action in
                    viewModel.walletActionPressed(action)
                }, subActionCallback: { subAction in
                    viewModel.walletSubActionPressed(subAction)
                })
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .unstoppableListRowInset()
                
                userDataContentViewsIfAvailable()
                
            }.environment(\.defaultMinListRowHeight, 28)
            .onChange(of: tabRouter.walletViewNavPath) { _ in
                updateNavTitleVisibility()
                tabRouter.isTabBarVisible = !isOtherScreenPushed
            }
            .animation(.default, value: viewModel.selectedWallet)
            .listStyle(.plain)
            .listRowSpacing(0)
            .clearListBackground()
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    HomeSettingsNavButtonView()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    moreActionsNavButton()
                }
                if viewModel.isWCSupported {
                    ToolbarItem(placement: .topBarTrailing) {
                        qrNavButtonView()
                    }
                }
            })
            .refreshable {
                logAnalytic(event: .didPullToRefresh)
                try? await appContext.walletsDataService.refreshDataForWallet(viewModel.selectedWallet)
            }
            .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension HomeWalletView {
    var isProfileButtonEnabled: Bool {
        viewModel.isProfileButtonEnabled && !isHomeInMaintenance
    }
    
    func walletActions() -> [WalletAction] {
        var actions: [WalletAction] = [.buy(enabled: viewModel.isBuyButtonEnabled)]
        if viewModel.isSendCryptoEnabled {
            actions.append(.send)
        }
        actions.append(contentsOf: [.receive, .profile(enabled: isProfileButtonEnabled)])
        return actions
    }
    
    func onAppear() {
        setupTitleView()
        viewModel.onAppear()
    }
    
    func setupTitleView() {
        let id = viewModel.selectedWallet.id
        navigationState?.setCustomTitle(customTitle: { HomeProfileSelectorNavTitleView(shouldHideAvatar: true) },
                                        id: id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            updateNavTitleVisibility()
        }
    }
    
    func updateNavTitleVisibility() {
        withAnimation {
            navigationState?.isTitleVisible = !isOtherScreenPushed && tabRouter.tabViewSelection == .wallets
        }
    }
    
    var isHomeInMaintenance: Bool {
        profilesAPIFlagTracker.maintenanceData?.isCurrentlyEnabled == true
    }
    
    @ViewBuilder
    func userDataContentViewsIfAvailable() -> some View {
        if isHomeInMaintenance {
            MaintenanceDetailsEmbeddedView(serviceType: .home,
                                           maintenanceData: profilesAPIFlagTracker.maintenanceData)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            userDataContentViews()
        }
    }
    
    @ViewBuilder
    func userDataContentViews() -> some View {
        contentTypeSelector()
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical)
            .unstoppableListRowInset()
        
        sortingOptionsForSelectedType()
            .environment(\.analyticsAdditionalProperties, [.homeContentType : viewModel.selectedContentType.rawValue])
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 0, trailing: 16))
        
        contentForSelectedType()
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.init(horizontal: 16))
    }

    @ViewBuilder
    func contentTypeSelector() -> some View {
        HomeWalletContentTypeSelectorView(selectedContentType: $viewModel.selectedContentType)
    }
    
    @ViewBuilder
    func contentForSelectedType() -> some View {
        switch viewModel.selectedContentType {
        case .tokens:
            tokensContentView()
        case .collectibles:
            collectiblesContentView()
        case .domains:
            domainsContentView()
        }
    }
    
    @ViewBuilder
    func sortingOptionsForSelectedType() -> some View {
        switch viewModel.selectedContentType {
        case .tokens:
            HomeWalletSortingSelectorView(sortingOptions: TokensSortingOptions.allCases,
                                          selectedOption: $viewModel.selectedTokensSortingOption)
        case .collectibles:
            HomeWalletSortingSelectorView(sortingOptions: CollectiblesSortingOptions.allCases,
                                          selectedOption: $viewModel.selectedCollectiblesSortingOption)
        case .domains:
            HomeWalletSortingSelectorView(sortingOptions: DomainsSortingOptions.allCases, 
                                          selectedOption: $viewModel.selectedDomainsSortingOption,
                                          additionalAction: .init(title: String.Constants.buy.localized(),
                                                                  icon: .plusIconNav,
                                                                  analyticName: .buyDomainsSectionHeader,
                                                                  callback: viewModel.buyDomainPressed))
        }
    }
    
    @ViewBuilder
    func tokensContentView() -> some View {
        tokensListView()
        HomeWalletMoreTokensView()
        notMatchingTokensListView()
    }
    
    @ViewBuilder
    func tokensListView() -> some View {
        LazyVStack(spacing: 20) {
            ForEach(viewModel.tokens) { token in
                Button {
                  
                } label: {
                    HomeWalletTokenRowView(token: token)
                }
                .padding(EdgeInsets(top: -12, leading: 0, bottom: -12, trailing: 0))
            }
        }
        .padding(EdgeInsets(top: 30, leading: 0, bottom: 12, trailing: 0))
    }
    
    @ViewBuilder
    func notMatchingTokensListView() -> some View {
        if !viewModel.chainsNotMatch.isEmpty {
            Line()
                .stroke(lineWidth: 1)
                .frame(height: 1)
                .foregroundStyle(Color.foregroundSecondary)
            HomeWalletExpandableSectionHeaderView(title: String.Constants.hidden.localized(),
                                                  isExpandable: true,
                                                  numberOfItemsInSection: viewModel.chainsNotMatch.count,
                                                  isExpanded: viewModel.isNotMatchingTokensVisible,
                                                  actionCallback: {
                viewModel.isNotMatchingTokensVisible.toggle()
                logButtonPressedAnalyticEvents(button: .notMatchingTokensSectionHeader,
                                               parameters: [.expand : String(viewModel.isNotMatchingTokensVisible),
                                                            .numberOfItemsInSection: String(viewModel.chainsNotMatch.count)])
            })
            if viewModel.isNotMatchingTokensVisible {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.chainsNotMatch) { description in
                        Button {
                            UDVibration.buttonTap.vibrate()
                            didSelectNotMatchingTokenDescription(description)
                            logButtonPressedAnalyticEvents(button: .notMatchingToken, 
                                                           parameters: [.chain: description.chain])
                        } label: {
                            HomeWalletTokenNotMatchingRowView(description: description)
                        }
                        .padding(EdgeInsets(top: -12, leading: 0, bottom: -12, trailing: 0))
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    func didSelectNotMatchingTokenDescription(_ description: NotMatchedRecordsDescription) {
        Task {
            let pullUpConfig = await ViewPullUpDefaultConfiguration.recordDoesNotMatchOwner(ticker: description.chain,
                                                                                            fullName: description.fullName,
                                                                                            ownerAddress: description.ownerWallet,      updateRecordsCallback: {
                viewModel.walletActionPressed(.profile(enabled: true))
            })
            tabRouter.pullUp = .default(pullUpConfig)
        }
    }
    
    @ViewBuilder
    func collectiblesContentView() -> some View {
        if viewModel.nftsCollections.isEmpty {
            HomeWalletCollectiblesEmptyView(walletAddress: viewModel.selectedWallet.address)
        } else {
            ForEach(viewModel.nftsCollections) { nftCollection in
                HomeWalletNFTsCollectionSectionView(collection: nftCollection, 
                                                    nftsCollectionsExpandedIds: $viewModel.nftsCollectionsExpandedIds,
                                                    nftSelectedCallback: didSelectNFT)
            }
        }
    }
    
    func didSelectNFT(_ nft: NFTDisplayInfo) {
        tabRouter.presentedNFT = nft
    }
    
    @ViewBuilder
    func domainsContentView() -> some View {
        HomeWalletsDomainsSectionView(domainsData: $viewModel.domainsData,
                                      domainSelectedCallback: viewModel.didSelectDomain,
                                      buyDomainCallback: viewModel.buyDomainPressed)
    }
    
    @ViewBuilder
    func qrNavButtonView() -> some View {
        Button {
            if case .mpc = viewModel.selectedWallet.udWallet.type,
               mpcFlagTracker.maintenanceData?.isCurrentlyEnabled == true {
                tabRouter.showSigningMessagesInMaintenancePullUp()
            } else {
                tabRouter.walletViewNavPath.append(.qrScanner(selectedWallet: viewModel.selectedWallet))
                logButtonPressedAnalyticEvents(button: .qrCode)
            }
        } label: {
            Image.qrBarCodeIcon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundDefault)
        }
    }
    
    @ViewBuilder
    func moreActionsNavButton() -> some View {
        Menu {
            ForEach(HomeWalletView.WalletAction.more.subActions, id: \.rawValue) { subAction in
                viewForMoreSubAction(subAction)
            }
        } label: {
            Image.dotsIcon
                .foregroundStyle(Color.foregroundDefault)
        }
        .onButtonTap {
            logButtonPressedAnalyticEvents(button: HomeWalletView.WalletAction.more.analyticButton)
        }
    }
    
    @ViewBuilder
    func viewForMoreSubAction(_ subAction: HomeWalletView.WalletSubAction) -> some View {
        Button(role: subAction.isDestructive ? .destructive : .cancel) {
            UDVibration.buttonTap.vibrate()
            viewModel.walletSubActionPressed(subAction)
            logButtonPressedAnalyticEvents(button: subAction.analyticButton)
        } label: {
            Label(
                title: { Text(subAction.title) },
                icon: { subAction.icon }
            )
        }
    }
}
