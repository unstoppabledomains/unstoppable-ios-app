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
    @StateObject var viewModel: HomeWalletViewModel
    @State private var isHeaderVisible: Bool = true
    @State private var scrollOffset: CGPoint = .zero
    @State private var isOtherScreenPresented: Bool = false
    let navigationState: NavigationStateManager?
    @Binding var isNavTitleVisible: Bool
    @Binding var isTabBarVisible: Bool
    var isOtherScreenPushed: Bool { !tabRouter.walletViewNavPath.isEmpty }
    
    var body: some View {
            OffsetObservingListView(offset: $scrollOffset) {
                HomeWalletHeaderRowView(wallet: viewModel.selectedWallet,
                                        domainNamePressedCallback: viewModel.domainNamePressed,
                                        didSelectDomainCallback: viewModel.didSelectChangeRR,
                                        purchaseDomainCallback: viewModel.buyDomainPressed)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .onAppearanceChange($isHeaderVisible)
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
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }.environment(\.defaultMinListRowHeight, 28)
            .onChange(of: tabRouter.walletViewNavPath) { _ in
                updateNavTitleVisibility()
                isTabBarVisible = !isOtherScreenPushed
            }
            .onChange(of: scrollOffset) { point in
                updateNavTitleVisibility()
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
                    searchButtonView()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    qrNavButtonView()
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
    struct NavigationTitleView: View {
        
        @Environment(\.imageLoadingService) private var imageLoadingService

        let wallet: WalletEntity
        @State private var avatar: UIImage?
        
        var body: some View {
            content()
                .onAppear(perform: loadAvatar)
                .onChange(of: wallet) { newValue in
                    avatar = nil
                    loadAvatar()
                }
        }
        
        private func loadAvatar() {
            Task {
                if let rrDomain = wallet.rrDomain {
                    avatar =  await imageLoadingService.loadImage(from: .domain(rrDomain), downsampleDescription: .mid)
                }
            }
        }
        
        @ViewBuilder
        private func content() -> some View {
            if let rrDomain = wallet.rrDomain {
                HStack {
                    UIImageBridgeView(image: avatar ?? .domainSharePlaceholder,
                                      width: 20,
                                      height: 20)
                    .squareFrame(20)
                    .clipShape(Circle())
                    Text(rrDomain.name)
                        .font(.currentFont(size: 16, weight: .semibold))
                        .foregroundStyle(Color.foregroundDefault)
                        .lineLimit(1)
                }
                .frame(height: 20)
            } else {
                Text(wallet.displayName)
                    .font(.currentFont(size: 16, weight: .semibold))
                    .foregroundStyle(Color.foregroundDefault)
                    .lineLimit(1)
                    .frame(height: 20)
            }
        }
    }
    
    func walletActions() -> [WalletAction] {
        [.buy, .receive, .profile(enabled: viewModel.selectedWallet.rrDomain != nil), .more]
    }
    
    func updateNavTitleVisibility() {
        let isNavTitleVisible = (scrollOffset.y + safeAreaInset.top > 60) || (!isHeaderVisible) &&
        !isOtherScreenPushed &&
        tabRouter.tabViewSelection == .wallets
        if self.isNavTitleVisible != isNavTitleVisible {
            setTitleViewIfNeeded()
            self.isNavTitleVisible = isNavTitleVisible
        }
    }
    
    func onAppear() {
        setTitleViewIfNeeded()
        viewModel.onAppear()
    }
    
    func setTitleViewIfNeeded() {
        let id = viewModel.selectedWallet.id
        if navigationState?.customViewID != id {
            navigationState?.setCustomTitle(customTitle: { NavigationTitleView(wallet: viewModel.selectedWallet) },
                                            id: id)
        }
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
                                                           parameters: [.chain: description.chain.rawValue])
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
            let pullUpConfig = await ViewPullUpDefaultConfiguration.recordDoesNotMatchOwner(chain: description.chain,
                                                                                            ownerAddress: description.ownerWallet, updateRecordsCallback: {
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
        HomeWalletsDomainsSectionView(domainsGroups: viewModel.domainsGroups,
                                      subdomains: viewModel.subdomains,
                                      domainSelectedCallback: viewModel.didSelectDomain,
                                      buyDomainCallback: viewModel.buyDomainPressed,
                                      isSubdomainsVisible: $viewModel.isSubdomainsVisible,
                                      domainsTLDsExpandedList: $viewModel.domainsTLDsExpandedList)
    }
    
    @ViewBuilder
    func qrNavButtonView() -> some View {
        NavigationLink(value: HomeWalletNavigationDestination.qrScanner(selectedWallet: viewModel.selectedWallet)) {
            Image.qrBarCodeIcon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundDefault)
        }
        .onButtonTap {
            logButtonPressedAnalyticEvents(button: .qrCode)
        }
    }
    
    @ViewBuilder
    func searchButtonView() -> some View {
        Button {
            logButtonPressedAnalyticEvents(button: .searchDomains)
            tabRouter.isSearchingDomains = true
        } label: {
            Image.searchIcon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundDefault)
        }
    }
}
