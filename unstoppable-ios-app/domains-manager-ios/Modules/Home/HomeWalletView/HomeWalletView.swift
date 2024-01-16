//
//  HomeWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.01.2024.
//

import SwiftUI

struct HomeWalletView: View {
    
    @StateObject private var viewModel = HomeWalletViewModel()
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            List {
                walletHeaderView()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                walletActionsView()
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
            .animation(.default, value: UUID())
        }
        .background(Color.backgroundDefault)
        .navigationTitle("Vault 1")
        .navigationBarTitleDisplayMode(.inline)

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
    func walletActionsView() -> some View {
        HStack {
            ForEach(WalletAction.allCases, id: \.self) { action in
                walletActionView(for: action)
            }
        }
    }
    
    @ViewBuilder
    func walletActionView(for action: WalletAction) -> some View {
        Button {
            viewModel.walletActionPressed(action)
        } label: {
            VStack(spacing: 4) {
                action.icon
                    .resizable()
                    .renderingMode(.template)
                    .squareFrame(20)
                Text(action.title)
                    .font(.currentFont(size: 13, weight: .medium))
                    .frame(height: 20)
            }
            .foregroundColor(.foregroundAccent)
            .frame(height: 72)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color.backgroundOverlay)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.borderMuted)
            }
        }
        .buttonStyle(.plain)
        .withoutAnimation()
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
            sortingOptionsView(sortingOptions: TokensSortingOptions.allCases, selectedOption: $viewModel.selectedTokensSortingOption)
        case .collectibles:
            sortingOptionsView(sortingOptions: CollectiblesSortingOptions.allCases, selectedOption: $viewModel.selectedCollectiblesSortingOption)
        case .domains:
            sortingOptionsView(sortingOptions: DomainsSortingOptions.allCases, selectedOption: $viewModel.selectedDomainsSortingOption)
        }
    }
    
    @ViewBuilder
    func sortingOptionsView(sortingOptions: [some HomeViewSortingOption],
                            selectedOption: Binding<some HomeViewSortingOption>) -> some View {
        Menu {
            Picker("", selection: selectedOption) {
                ForEach(sortingOptions,
                        id: \.self) {
                    option in
                    Text(option.title)
                }
            }
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Image.filterIcon
                    .resizable()
                    .squareFrame(16)
                Text(selectedOption.wrappedValue.title)
                    .font(.currentFont(size: 14, weight: .medium))
                Line()
                    .stroke(lineWidth: 1)
                    .offset(y: 10)
            }
            .frame(height: 20)
        }
        .withoutAnimation()
        .foregroundStyle(Color.foregroundSecondary)
        .padding(EdgeInsets(top: -16, leading: 0, bottom: 0, trailing: 0))
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
                                                    nftAppearCallback: viewModel.loadIconIfNeededForNFT)
            }
        }
    }
    
    @ViewBuilder
    func domainsContentView() -> some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(viewModel.domains, id: \.name) { domain in
                Image(uiImage: UIImage.Preview.previewLandscape!)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview {
    NavigationView {
        HomeWalletView()
    }
}

