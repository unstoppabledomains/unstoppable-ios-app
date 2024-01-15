//
//  HomeWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.01.2024.
//

import SwiftUI

struct HomeWalletView: View {
    
    @ObservedObject private var presenter = HomeWalletViewPresenter()
    
    private let columns = [
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
        VStack(alignment: .center, spacing: 20) {
            Image(uiImage: UIImage.Preview.previewPortrait!)
                .resizable()
                .squareFrame(80)
                .clipShape(Circle())
                .background(Color.clear)
            
            Button {
                presenter.domainNamePressed()
            } label: {
                HStack {
                    Text("dans.crypto")
                        .font(.currentFont(size: 16, weight: .medium))
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .squareFrame(20)
                }
                .foregroundStyle(Color.foregroundSecondary)
            }
            .buttonStyle(.plain)
            
            Text("200$")
                .titleText()
        }
        .frame(maxWidth: .infinity)
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
            presenter.walletActionPressed(action)
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
        HomeWalletContentTypeSelectorView(selectedContentType: $presenter.selectedContentType)
    }
    
    @ViewBuilder
    func contentForSelectedType() -> some View {
        switch presenter.selectedContentType {
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
        LazyVStack(spacing: 0) {
            ForEach(presenter.tokens) { token in
                Button {
                    
                } label: {
                    HomeWalletTokenRowView(token: token)
                }
            }
        }
    }

    @ViewBuilder
    func collectiblesContentView() -> some View {
        HomeWalletCollectiblesEmptyView(walletAddress: presenter.walletAddress)
    }
    
    @ViewBuilder
    func domainsContentView() -> some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(presenter.domains, id: \.name) { domain in
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

