//
//  HomeWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.01.2024.
//

import SwiftUI

struct HomeWalletView: View {
    
    @ObservedObject private var viewModel = HomeWalletViewModel()
    
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
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.borderMuted)
            }
        }
        .buttonStyle(.plain)
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
    }

    @ViewBuilder
    func collectiblesContentView() -> some View {
        HomeWalletCollectiblesEmptyView(walletAddress: viewModel.walletAddress)
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

