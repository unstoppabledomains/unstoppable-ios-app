//
//  HomeWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.01.2024.
//

import SwiftUI

struct HomeWalletView: View {
    
    @StateObject private var viewModel = HomeWalletViewModel()
    @State private var selectedNFT: NFTDisplayInfo?
    
    var body: some View {
        ZStack {
            List {
                walletHeaderView()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                HomeWalletActionsView(actionCallback: { action in
                    viewModel.walletActionPressed(action)
                }, subActionCallback: { subAction in
                    viewModel.walletSubActionPressed(subAction)
                })
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
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
            .listStyle(.plain)
            .clearListBackground()
            .background(.clear)
            .animatedFromiOS16()
        }
        .background(Color.backgroundDefault)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedNFT, content: { nft in
            NFTDetailsView(nft: nft)
        })
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
                Button {
                    
                } label: {
                    Image.qrBarCodeIcon
                        .resizable()
                        .squareFrame(24)
                        .foregroundStyle(Color.foregroundDefault)
                }
            }
        })

    }
}

// MARK: - Private methods
private extension HomeWalletView {
    @ViewBuilder
    func walletHeaderView() -> some View {
        HomeWalletHeaderView(wallet: viewModel.selectedWallet,
                             totalBalance: viewModel.totalBalance,
                             domainNamePressedCallback: viewModel.domainNamePressed)
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
                HomeWalletTokenRowView(token: token, 
                                       onAppear: {
                    viewModel.loadIconIfNeededFor(token: token)
                })
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
                                                    nftAppearCallback: viewModel.loadIconIfNeededForNFT, 
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

#Preview {
    NavigationView {
        HomeWalletView()
    }
}

