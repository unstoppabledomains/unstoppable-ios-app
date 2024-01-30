//
//  HomeWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.01.2024.
//

import SwiftUI

struct HomeWalletView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

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
            .animation(.default, value: UUID())
            .listStyle(.plain)
            .clearListBackground()
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: NavigationDestination.self) { destination in
                viewFor(navigationDestination: destination)
                    .ignoresSafeArea()
                    .onAppearanceChange($isOtherScreenPresented)
            }
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    settingsNavButtonView()
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
            state.customTitle = navigationView
        }, path: $tabRouter.walletViewNavPath)
    }
}

// MARK: - Private methods
private extension HomeWalletView {
    @ViewBuilder
    func navigationView() -> some View {
        if let rrDomain = viewModel.selectedWallet.rrDomain {
            HStack {
                UIImageBridgeView(image: imageLoadingService.cachedImage(for: .domain(rrDomain)) ?? .domainSharePlaceholder,
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
            Text(viewModel.selectedWallet.displayName)
                .font(.currentFont(size: 16, weight: .semibold))
                .foregroundStyle(Color.foregroundDefault)
                .lineLimit(1)
                .frame(height: 20)
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
        ForEach(viewModel.tokens) { token in
            Button {
                
            } label: {
                HomeWalletTokenRowView(token: token)
            }
            .padding(EdgeInsets(top: -12, leading: 0, bottom: -12, trailing: 0))
        }
        HomeWalletMoreTokensView()
            .offset(y: -HomeWalletTokenRowView.height + 25)
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
    func settingsNavButtonView() -> some View {
        NavigationLink(value: NavigationDestination.settings) {
            Image.gearshape
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundDefault)
        }
    }
    
    @ViewBuilder
    func qrNavButtonView() -> some View {
        NavigationLink(value: NavigationDestination.qrScanner) {
            Image.qrBarCodeIcon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundDefault)
        }
    }
    
    @ViewBuilder
    func viewFor(navigationDestination: NavigationDestination) -> some View {
        switch navigationDestination {
        case .settings:
            SettingsViewControllerWrapper()
                .toolbar(.hidden, for: .navigationBar)
        case .qrScanner:
            QRScannerViewControllerWrapper(selectedWallet: viewModel.selectedWallet, qrRecognizedCallback: { })
                .navigationTitle(String.Constants.scanQRCodeTitle.localized())
                .navigationBarTitleDisplayMode(.inline)
        case .minting(let mode, let mintedDomains, let domainsMintedCallback):
            MintDomainsNavigationControllerWrapper(mode: mode,
                                                   mintedDomains: mintedDomains,
                                                   domainsMintedCallback: domainsMintedCallback,
                                                   mintingNavProvider: { mintingNav in
                tabRouter.mintingNav = mintingNav
            })
            .toolbar(.hidden, for: .navigationBar)
        case .purchaseDomains(let callback):
            PurchaseDomainsNavigationControllerWrapper(domainsPurchasedCallback: callback)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Open methods
extension HomeWalletView {
    enum NavigationDestination: Hashable {
        case settings
        case qrScanner
        case minting(mode: MintDomainsNavigationController.Mode,
                     mintedDomains: [DomainDisplayInfo],
                     domainsMintedCallback: MintDomainsNavigationController.DomainsMintedCallback)
        case purchaseDomains(domainsPurchasedCallback: PurchaseDomainsNavigationController.DomainsPurchasedCallback)
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.settings, .settings):
                return true
            case (.qrScanner, .qrScanner):
                return true
            case (.minting, .minting):
                return true
            case (.purchaseDomains, .purchaseDomains):
                return true
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .settings:
                hasher.combine(0)
            case .qrScanner:
                hasher.combine(1)
            case .minting:
                hasher.combine(2)
            case .purchaseDomains:
                hasher.combine(3)
            }
        }
        
    }
}

#Preview {
    NavigationView {
        HomeWalletView(viewModel: .init(selectedWallet: MockEntitiesFabric.Wallet.mockEntities().first!,
                                        router: .init()))
    }
}

