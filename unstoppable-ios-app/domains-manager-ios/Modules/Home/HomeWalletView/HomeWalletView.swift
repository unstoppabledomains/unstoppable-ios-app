//
//  HomeWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.01.2024.
//

import SwiftUI

struct HomeWalletView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    @StateObject var viewModel: HomeWalletViewModel
    @State private var isHeaderVisible: Bool = true
    @State private var isOtherScreenPresented: Bool = false
    @State private var selectedNFT: NFTDisplayInfo?
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
                    navigationState?.isTitleVisible = !isOtherScreenPresented && !isHeaderVisible
                }
            }
            .onChange(of: isOtherScreenPresented) { newValue in
                withAnimation {
                    navigationState?.isTitleVisible = !isOtherScreenPresented && !isHeaderVisible
                }
            }
            .listStyle(.plain)
            .clearListBackground()
            .background(.clear)
            .animatedFromiOS16()
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedNFT, content: { nft in
                NFTDetailsView(nft: nft)
            })
            .modifier(ShowingWalletSelection(isSelectWalletPresented: $viewModel.isSelectWalletPresented))
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        
                    } label: {
                        Image.gearshape
                            .resizable()
                            .squareFrame(24)
                            .foregroundStyle(Color.foregroundDefault)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        if let domain = viewModel.selectedWallet.rrDomain {
                            QRScannerViewControllerWrapper(selectedDomain: domain, qrRecognizedCallback: {
                                
                            })
                            .ignoresSafeArea()
                            .navigationTitle(String.Constants.scanQRCodeTitle.localized())
                            .onAppearanceChange($isOtherScreenPresented)
                        }
                    } label: {
                        Image.qrBarCodeIcon
                            .resizable()
                            .squareFrame(24)
                            .foregroundStyle(Color.foregroundDefault)
                    }
                }
            })
        }, customTitle: {
            navigationView()
        }, navigationStateProvider: { state in
            self.navigationState = state
            state.customTitle = navigationView
        })
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
            .frame(maxWidth: 240)
        } else {
            Text(viewModel.selectedWallet.displayName)
                .font(.currentFont(size: 16, weight: .semibold))
                .foregroundStyle(Color.foregroundDefault)
                .lineLimit(1)
                .frame(height: 20)
                .frame(maxWidth: 240)
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
        selectedNFT = nft
    }
    
    @ViewBuilder
    func domainsContentView() -> some View {
        HomeWalletsDomainsSectionView(domains: viewModel.domains)
    }
}

// MARK: - Private methods
private extension HomeWalletView {
    struct ShowingWalletSelection: ViewModifier {
        @Binding var isSelectWalletPresented: Bool
        
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $isSelectWalletPresented, content: {
                    HomeWalletWalletSelectionView()
                        .adaptiveSheet()
                })
        }
    }
}

#Preview {
    NavigationView {
        HomeWalletView(viewModel: .init(selectedWallet: WalletEntity.mock().first!))
    }
}

