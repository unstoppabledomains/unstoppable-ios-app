//
//  HomeWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.01.2024.
//

import SwiftUI

struct HomeWalletView: View {
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @StateObject var viewModel: HomeWalletViewModel
    @State private var isHeaderVisible: Bool = true
    @State private var isOtherScreenPresented: Bool = false
    @State private var navigationState: NavigationStateManager?
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            List {
                HomeWalletHeaderRowView(wallet: viewModel.selectedWallet)
                    .onAppearanceChange($isHeaderVisible)
                HomeWalletProfileSelectionView(wallet: viewModel.selectedWallet,
                                               domainNamePressedCallback: viewModel.domainNamePressed)
                HomeWalletTotalBalanceView(wallet: viewModel.selectedWallet)
                
                HomeWalletActionsView(actionCallback: { action in
                    viewModel.walletActionPressed(action)
                }, subActionCallback: { subAction in
                    viewModel.walletSubActionPressed(subAction)
                })
               
                contentTypeSelector()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical)
                sortingOptionsForSelectedType()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                contentForSelectedType()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onChange(of: isHeaderVisible) { newValue in
                withAnimation {
                    navigationState?.isTitleVisible = 
                    !isOtherScreenPresented &&
                    !isHeaderVisible &&
                    tabRouter.tabViewSelection == .wallets
                }
            }
            .onChange(of: isOtherScreenPresented) { newValue in
                withAnimation {
                    navigationState?.isTitleVisible = !isOtherScreenPresented && !isHeaderVisible
                    tabRouter.isTabBarVisible = !isOtherScreenPresented
                }
            }
            .animation(.default, value: viewModel.selectedWallet)
            .listStyle(.plain)
            .clearListBackground()
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeWalletNavigationDestination.self) { destination in
                HomeWalletLinkNavigationDestination.viewFor(navigationDestination: destination)
                    .ignoresSafeArea()
                    .onAppearanceChange($isOtherScreenPresented)
            }
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    HomeSettingsNavButtonView()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    qrNavButtonView()
                }
            })
            .refreshable {
                try? await appContext.walletsDataService.refreshDataForWallet(viewModel.selectedWallet)
            }
        }, navigationStateProvider: { state in
            self.navigationState = state
            state.customTitle = { NavigationTitleView(wallet: viewModel.selectedWallet) }
        }, path: $tabRouter.walletViewNavPath)
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
            HomeWalletSortingSelectorView(sortingOptions: TokensSortingOptions.allCases, selectedOption: $viewModel.selectedTokensSortingOption)
        case .collectibles:
            HomeWalletSortingSelectorView(sortingOptions: CollectiblesSortingOptions.allCases, selectedOption: $viewModel.selectedCollectiblesSortingOption)
        case .domains:
            HomeWalletSortingSelectorView(sortingOptions: DomainsSortingOptions.allCases, selectedOption: $viewModel.selectedDomainsSortingOption)
        }
    }
    
    @ViewBuilder
    func tokensContentView() -> some View {
        tokensListView()
        HomeWalletMoreTokensView()
            .padding(EdgeInsets(top: -12, leading: 0, bottom: -12, trailing: 0))
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
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
    }
    
    @ViewBuilder
    func notMatchingTokensListView() -> some View {
        if !viewModel.chainsNotMatch.isEmpty {
            Line()
                .stroke(lineWidth: 1)
                .frame(height: 1)
                .foregroundStyle(Color.foregroundSecondary)
            HomeWalletExpandableSectionHeaderView(title: "Hidden",
                                                  isExpandable: true,
                                                  numberOfItemsInSection: viewModel.chainsNotMatch.count,
                                                  isExpanded: viewModel.isNotMatchingTokensVisible,
                                                  actionCallback: {
                viewModel.isNotMatchingTokensVisible.toggle()
            })
            if viewModel.isNotMatchingTokensVisible {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.chainsNotMatch) { description in
                        Button {
                            UDVibration.buttonTap.vibrate()
                            didSelectNotMatchingTokenDescription(description)
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
                viewModel.walletActionPressed(.profile)
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
        HomeWalletsDomainsSectionView(domains: viewModel.domains,
                                      subdomains: viewModel.subdomains,
                                      domainSelectedCallback: didSelectDomain, isSubdomainsVisible: $viewModel.isSubdomainsVisible)
    }
    
    func didSelectDomain(_ domain: DomainDisplayInfo) {
        tabRouter.presentedDomain = .init(domain: domain, wallet: viewModel.selectedWallet)
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
            
        }
    }
}

#Preview {
    NavigationView {
        let router = HomeTabRouter(accountState: .walletAdded(MockEntitiesFabric.Wallet.mockEntities().first!))
        
        return HomeWalletView(viewModel: .init(selectedWallet: MockEntitiesFabric.Wallet.mockEntities().first!,
                                               router: router))
        .environmentObject(router)
    }
}

